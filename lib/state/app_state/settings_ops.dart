part of '../app_state.dart';

/// Nastavení, záloha, export.
extension SettingsOps on AppState {
  /// Pauza po sérii daného cviku: vlastní, jinak výchozí.
  int restFor(String? exerciseId) =>
      (exerciseId == null ? null : profile.restFor(exerciseId)) ??
      profile.restSeconds;

  /// Vlastní pauza u cviku; `null` vrátí výchozí.
  Future<void> setExerciseRest(
    String exerciseId,
    int? seconds,
  ) => _updateProfile((p) {
    final map = {
      ...?(p.extra[ProfileKey.restByExercise] as Map?)?.cast<String, dynamic>(),
    };
    if (seconds == null) {
      map.remove(exerciseId);
    } else {
      map[exerciseId] = seconds.clamp(15, 600);
    }
    return p.withExtra({ProfileKey.restByExercise: map.isEmpty ? null : map});
  });

  Future<void> setPreferences({int? restSeconds, double? weightStep}) =>
      _updateProfile(
        (p) => p.withExtra({
          ProfileKey.restSeconds: ?restSeconds?.clamp(15, 600),
          if (weightStep != null && weightSteps.contains(weightStep))
            ProfileKey.weightStep: weightStep,
        }),
      );

  /// Zapíše váhu; `false` = nesmyslná hodnota.
  Future<bool> addBodyweight(double kg, {DateTime? now}) async {
    if (!validBodyWeight(kg)) return false;
    final entry = BodyWeight(
      id: newId(),
      date: now ?? DateTime.now(),
      kg: double.parse(kg.toStringAsFixed(1)),
    );
    await _enqueue(() => store.put(Kinds.bodyweight, entry.toJson()));
    bodyweights = [entry, ...bodyweights]
      ..sort((a, b) => b.date.compareTo(a.date));
    _changed();
    return true;
  }

  Future<void> removeBodyweight(String id) async {
    await _enqueue(() => store.remove(id));
    bodyweights = bodyweights.where((b) => b.id != id).toList();
    _changed();
  }

  /// Vrátí smazaný záznam váhy („Vrátit“ po smazání).
  Future<void> restoreBodyweight(BodyWeight entry) async {
    if (bodyweights.any((b) => b.id == entry.id)) return;
    await _enqueue(() => store.put(Kinds.bodyweight, entry.toJson()));
    bodyweights = [entry, ...bodyweights]
      ..sort((a, b) => b.date.compareTo(a.date));
    _changed();
  }

  /// Záznamy deníku z jednoho dne, nejnovější první.
  List<FoodEntry> foodsOn(String day) => [
    for (final f in foods)
      if (f.day == day) f,
  ];

  /// Naposledy zapsaná jídla (bez duplicit podle názvu), k rychlému opakování.
  List<FoodEntry> get recentFoods {
    final seen = <String>{};
    return [
      for (final f in foods)
        if (seen.add(AppState.foodKey(f))) f,
    ].take(8).toList();
  }

  /// Připnutá jídla (šablony se stejným množstvím), nejnověji připnuté první.
  List<FoodEntry> get favoriteFoods => [
    if (profile.extra[ProfileKey.favoriteFoods] case final List list)
      for (final f in list)
        if (f is Map<String, dynamic>) ?AppState._tryFood(f),
  ];

  bool isFavoriteFood(FoodEntry f) =>
      favoriteFoods.any((x) => AppState.foodKey(x) == AppState.foodKey(f));

  /// Připne nebo odepne jídlo; vrací `true`, když je teď oblíbené.
  /// Nejvýš [maxFavoriteFoods], nejstarší připnuté vypadne.
  Future<bool> toggleFavoriteFood(FoodEntry f) async {
    late bool pinned;
    await _updateProfile((p) {
      final raw = p.extra[ProfileKey.favoriteFoods];
      final current = [
        if (raw is List)
          for (final x in raw)
            if (x is Map<String, dynamic>) ?AppState._tryFood(x),
      ];
      final key = AppState.foodKey(f);
      final rest = [
        for (final x in current)
          if (AppState.foodKey(x) != key) x,
      ];
      pinned = rest.length == current.length;
      final next = pinned ? [f, ...rest].take(maxFavoriteFoods) : rest;
      return p.withExtra({
        ProfileKey.favoriteFoods: next.isEmpty
            ? null
            : [for (final x in next) x.toJson()],
      });
    });
    return pinned;
  }

  /// Rychlé přidání: oblíbená první, pak nedávná bez opakování.
  List<FoodEntry> get quickFoods {
    final favorites = favoriteFoods;
    final keys = {for (final f in favorites) AppState.foodKey(f)};
    return [
      ...favorites,
      for (final f in recentFoods)
        if (!keys.contains(AppState.foodKey(f))) f,
    ];
  }

  /// Uloží nový záznam, nebo přepíše existující (stejné `id`).
  /// Vrací chybovou zprávu, nebo `null` po uložení.
  Future<String?> saveFood(FoodEntry entry) async {
    final error = validateFood(
      name: entry.name,
      amount: entry.amount,
      basis: entry.basis,
      values: entry.values,
    );
    if (error != null) return error;
    if (parseDayKey(entry.day) == null) return 'Neplatný den.';
    await _enqueue(() => store.put(Kinds.food, entry.toJson()));
    foods = [
      entry,
      for (final f in foods)
        if (f.id != entry.id) f,
    ]..sort(AppState._newestFood);
    _changed();
    return null;
  }

  Future<void> removeFood(String id) async {
    await _enqueue(() => store.remove(id));
    foods = foods.where((f) => f.id != id).toList();
    _changed();
  }
}

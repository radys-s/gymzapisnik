part of '../app_state.dart';

/// AI kouč: spíž, cíle, kontext pro návrhy.
extension CoachOps on AppState {
  /// Změna profilu počítaná až ve frontě z posledního uloženého stavu:
  /// dvě rychlé změny (barva, souhlas) se navzájem nepřepíšou.
  Future<void> _updateProfile(Profile Function(Profile current) change) =>
      _enqueue(() async {
        final next = change(profile);
        await store.put(Kinds.profile, next.toJson());
        profile = next;
        _changed();
      });

  /// Náhodné ID instalace pro denní limit AI; vznikne při prvním použití.
  /// Nepatří do zálohy (jiné zařízení = jiná instalace).
  Future<String> installId() async {
    late String id;
    await _updateProfile((p) {
      final saved = p.extra[ProfileKey.installId];
      id = saved is String && saved.length == 36 ? saved : newId();
      return p.withExtra({ProfileKey.installId: id});
    });
    return id;
  }

  /// Poslední potvrzený seznam potravin doma.
  List<PantryItem> get pantry {
    final raw = profile.extra[ProfileKey.pantry];
    if (raw is! List) return const [];
    return [for (final i in raw) ?PantryItem.tryParse(i)];
  }

  Future<void> savePantry(List<PantryItem> items) => _updateProfile(
    (p) => p.withExtra({
      ProfileKey.pantry: items.isEmpty
          ? null
          : [for (final i in mergePantry([], items)) i.toJson()],
    }),
  );

  Set<String> get pantryExcluded => {
    for (final name
        in (profile.extra[ProfileKey.pantryExcluded] as List? ?? const []))
      if (name is String) pantryKey(name),
  };

  int get pantryMinutes =>
      [10, 20, 40].contains(profile.extra[ProfileKey.pantryMinutes])
      ? profile.extra[ProfileKey.pantryMinutes] as int
      : 20;

  Future<void> savePantrySelection(Set<String> excluded, int minutes) =>
      _updateProfile(
        (p) => p.withExtra({
          ProfileKey.pantryExcluded: excluded.toList()..sort(),
          ProfileKey.pantryMinutes: [10, 20, 40].contains(minutes)
              ? minutes
              : 20,
        }),
      );

  List<MealIdea> get savedMealIdeas =>
      parseMeals({'meals': profile.extra[ProfileKey.mealIdeas]});

  Future<void> saveMealIdeas(List<MealIdea> meals) => _updateProfile(
    (p) => p.withExtra({
      ProfileKey.mealIdeas: [for (final meal in meals.take(6)) meal.toJson()],
    }),
  );

  /// Úvod je za uživatelem; zároveň zná novinky této verze.
  Future<void> finishWelcome(String version) => _updateProfile(
    (p) => p.withExtra({
      ProfileKey.welcomeSeen: true,
      ProfileKey.seenVersion: version,
    }),
  );

  Future<void> markVersionSeen(String version) =>
      _updateProfile((p) => p.withExtra({ProfileKey.seenVersion: version}));

  /// Zapamatuje si záložku; chyba uložení nesmí rozbít přepnutí.
  Future<void> setLastTab(int tab) async {
    try {
      await _updateProfile(
        (p) => p.withExtra({
          ProfileKey.tab: tab > 0 && tab <= 3 ? tab : null,
          ProfileKey.legacyTab: null,
          ProfileKey.legacyLastTab: null,
        }),
      );
    } catch (e) {
      debugPrint('Záložku se nepodařilo uložit: $e');
    }
  }

  /// Chat s AI trenérem: posledních [maxCoachChat] zpráv v zařízení.
  List<ChatMessage> get coachChat => [
    if (profile.extra[ProfileKey.coachChat] case final List list)
      for (final m in list) ?ChatMessage.tryParse(m),
  ];

  Future<void> saveCoachChat(List<ChatMessage> messages) => _updateProfile(
    (p) => p.withExtra({
      ProfileKey.coachChat: messages.isEmpty
          ? null
          : [
              for (final m in messages.skip(
                messages.length > maxCoachChat
                    ? messages.length - maxCoachChat
                    : 0,
              ))
                m.toJson(),
            ],
    }),
  );

  /// Souhrn tréninků pro trenéra (bez jména a poznámek).
  Map<String, dynamic> trainerContext([DateTime? now]) {
    final at = now ?? DateTime.now();
    return coachContext(
      now: at,
      workouts: workouts,
      exercise: exercise,
      adult: profile.adult,
      weekGoal: weekGoal,
      split: split,
      todayDay: todaySplitDay,
      todaySuggestions: [
        if (todayDay case final day?)
          for (final (_, s) in plan(day)) s,
      ],
      mission: mission(at),
      trainingDays: profile.trainingDays,
      plan: planAnswers,
      bodyweightKg: bodyweights.firstOrNull?.kg,
      recovery: recoveryByFocus(
        workouts,
        at,
        muscleOf: (id) => exercise(id).muscle,
      ),
      focusNames: {for (final f in dayFocuses) f.id: f.name},
      weekFocus: weekFocus(at),
      focusProgress: weekFocusProgress(at),
      plateaus: [
        for (final id in {
          for (final w in workouts.take(10))
            for (final e in w.exercises) e.exerciseId,
        })
          ?plateauFor(id),
      ],
      protein: proteinWeek(at),
    );
  }

  /// Fakta pro místního trenéra: stejná čísla jako hlavní karta.
  CoachFacts coachFacts([DateTime? now]) {
    final at = now ?? DateTime.now();
    final s = split;
    final day = todayDay;
    final names = {for (final f in dayFocuses) f.id: f.name};
    final recovery = recoveryByFocus(
      workouts,
      at,
      muscleOf: (id) => exercise(id).muscle,
    );
    String label(String id) => exercise(id).name;

    final last = finishedNewestFirst(workouts).firstOrNull;
    final days = profile.trainingDays;
    const short = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];
    return CoachFacts(
      mission: mission(at),
      program: s?.name,
      day: day?.name,
      dayNumber: todaySplitDay + 1,
      dayCount: s?.days.length ?? 1,
      plan: [
        if (day != null)
          for (final (pl, sug) in plan(day))
            PlanLine(
              name: label(pl.exerciseId),
              sets: pl.sets,
              repMin: pl.repMin,
              repMax: pl.repMax,
              suggestion: sug,
              weighted: typeOf(pl.exerciseId) == ExerciseType.weighted,
              start: sug.kind == SuggestionKind.start && sug.weight > 0
                  ? startLoad(
                      pl.exerciseId,
                      planAnswers?.level ?? PlanLevel.beginner,
                    )?.label
                  : null,
            ),
      ],
      hardSets: {
        for (final e in weeklyHardSets(
          workouts,
          at,
          (id) => exercise(id).muscle,
        ).entries)
          names[e.key] ?? e.key: e.value,
      },
      ready: [
        for (final r in recovery.values)
          if (r.isReady && r.focusId != 'core') names[r.focusId] ?? r.focusId,
      ],
      tired: [
        for (final r in recovery.values)
          if (!r.isReady) names[r.focusId] ?? r.focusId,
      ],
      stalls: findStalls(workouts, at, typeOf, label),
      trainingDaysLeft: [
        if (days != null)
          for (final d in days)
            if (d >= at.weekday) short[d - 1],
      ],
      daysSinceLast: last == null ? null : at.difference(last.date).inDays,
      activeWorkout: active != null,
    );
  }

  Future<void> acceptAiNotice() =>
      _updateProfile((p) => p.withExtra({ProfileKey.aiNotice: true}));

  /// Krok úvodu, na kterém uživatel skončil (aplikace se mohla zavřít).
  int get onboardingStep {
    final v = profile.extra[ProfileKey.onboardingStep];
    return v is num && v.isFinite ? v.toInt().clamp(0, 9) : 0;
  }

  /// Uloží krok úvodu; s [draft] i rozpracované odpovědi, ať je po
  /// zavření aplikace uprostřed úvodu neztratí.
  Future<void> setOnboardingStep(int step, {PlanAnswers? draft}) =>
      _updateProfile(
        (p) => p.withExtra({
          ProfileKey.onboardingStep: step,
          if (draft != null) ProfileKey.planDraft: draft.toJson(),
        }),
      );

  /// Rozpracované odpovědi z úvodu, dokud se plán neuloží.
  PlanAnswers? get planDraft =>
      PlanAnswers.tryParse(profile.extra[ProfileKey.planDraft]);

  /// Doporučený cíl z poslední tělesné váhy a cíle z dotazníku;
  /// `null` bez zapsané váhy.
  SuggestedTargets? get suggestedTargets {
    final kg = bodyweights.firstOrNull?.kg;
    if (kg == null) return null;
    return suggestTargets(
      kg: kg,
      goal: (planAnswers ?? const PlanAnswers()).goal,
      adult: !profile.restrictWeightLoss,
      plan: planAnswers,
    );
  }

  /// Nastaví cíle (`null` = bez cíle). Kalorický cíl jen pro dospělé.
  Future<void> setNutritionTargets({double? protein, double? kcal}) =>
      _updateProfile(
        (p) => p.withExtra({
          ProfileKey.proteinTarget: protein?.clamp(20, 400).roundToDouble(),
          ProfileKey.kcalTarget: p.restrictWeightLoss
              ? null
              : kcal?.clamp(1000, 6000).roundToDouble(),
        }),
      );

  /// Bílkoviny posledních sedmi dní (bez dneška, ten ještě není celý).
  /// `null` bez cíle nebo s méně než třemi zapsanými dny.
  ProteinWeek? proteinWeek([DateTime? now]) {
    final target = profile.proteinTarget;
    if (target == null) return null;
    final today = dayStart(now ?? DateTime.now());
    final key = (foods, dayKey(today), target);
    final cached = _proteinCache;
    if (cached != null &&
        identical(cached.key.$1, key.$1) &&
        cached.key.$2 == key.$2 &&
        cached.key.$3 == key.$3) {
      return cached.value;
    }
    final byDay = <String, List<FoodEntry>>{};
    for (final f in foods) {
      (byDay[f.day] ??= []).add(f);
    }
    final eaten = <double>[];
    for (var i = 1; i <= 7; i++) {
      final day =
          byDay[dayKey(DateTime(today.year, today.month, today.day - i))];
      if (day == null) continue;
      final totals = totalsOf(day);
      // Den se zapsanou jen kávou nic neříká: počítají se dny, kdy je
      // zapsané aspoň nějaké jídlo navíc.
      if (totals.kcal >= AppState._proteinMinKcal) eaten.add(totals.protein);
    }
    final value = eaten.length < 3
        ? null
        : (
            average: eaten.reduce((a, b) => a + b) / eaten.length,
            target: target,
            days: eaten.length,
          );
    _proteinCache = (key: key, value: value);
    return value;
  }

  /// Dny tohoto týdne, kdy snědené bílkoviny dosáhly cíle.
  int proteinDaysThisWeek([DateTime? now]) {
    final target = profile.proteinTarget;
    if (target == null) return 0;
    final at = now ?? DateTime.now();
    final monday = weekStart(at);
    var n = 0;
    for (var i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      if (day.isAfter(at)) break;
      if (totalsOf(foodsOn(dayKey(day))).protein >= target) n++;
    }
    return n;
  }

  /// Týdenní cíl; po skončení týdne neplatí.
  WeekFocus? weekFocus([DateTime? now]) {
    final f = WeekFocus.tryParse(profile.extra[weekFocusKey]);
    return f != null && f.activeAt(now ?? DateTime.now()) ? f : null;
  }

  Future<void> setWeekFocus(
    FocusKind? kind, {
    String? exerciseId,
    DateTime? now,
  }) => _updateProfile(
    (p) => p.withExtra({
      weekFocusKey: kind == null
          ? null
          : WeekFocus(
              kind,
              week: weekStart(now ?? DateTime.now()),
              exerciseId: exerciseId,
            ).toJson(),
    }),
  );

  /// Stav týdenního cíle; `null` bez cíle.
  FocusProgress? weekFocusProgress([DateTime? now]) {
    final at = now ?? DateTime.now();
    final f = weekFocus(at);
    if (f == null) return null;
    return focusProgress(
      f,
      workouts: workouts,
      now: at,
      typeOf: typeOf,
      nameOf: (id) => exercise(id).name,
      weekGoal: weekGoal,
      proteinDays: proteinDaysThisWeek(at),
    );
  }

  /// Zaseknutí u cviku; `null`, když váha roste nebo je málo historie.
  Plateau? plateauFor(String exerciseId) => plateauOf(
    exerciseId,
    typeOf(exerciseId),
    exerciseHistory(workouts, exerciseId),
  );

  /// Ohodnotí dokončený trénink; `null` hodnocení smaže.
  Future<void> rateWorkout(Workout workout, WorkoutRating? rating) async {
    if (!workout.finished) throw StateError('Trénink není dokončený.');
    final edited = workout.copy();
    if (rating == null) {
      edited.extra.remove(ratingKey);
    } else {
      edited.extra[ratingKey] = rating.name;
    }
    // Jen hodnocení: série zůstanou přesně, jak byly uložené.
    await _enqueue(() => store.put(Kinds.workout, edited.toJson()));
    workouts = [for (final w in workouts) w.id == edited.id ? edited : w];
    _changed();
  }

  /// Kolik bílkovin dnes zbývá do cíle; `null` bez cíle.
  double? proteinLeft([DateTime? now]) {
    final target = profile.proteinTarget;
    if (target == null) return null;
    final eaten = totalsOf(foodsOn(dayKey(now ?? DateTime.now()))).protein;
    return (target - eaten).clamp(0, target).toDouble();
  }

  /// Kontext pro návrh jídel: dnešní trénink, snědeno, zbývající bílkoviny.
  MealContext mealContext({required int maxMinutes, DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = dayKey(at);
    final totals = totalsOf(foodsOn(today));
    final trainedToday = workouts.any((w) => dayKey(w.date.toLocal()) == today);
    return MealContext(
      trainingToday: trainedToday || mission(at).shouldTrain,
      eatenKcal: totals.kcal,
      eatenProtein: totals.protein,
      proteinLeft: proteinLeft(at),
      maxMinutes: maxMinutes,
      adult: profile.adult,
    );
  }

  String exportBackup({DateTime? now}) => encodeBackup(
    Backup(
      exportedAt: now ?? DateTime.now(),
      workouts: workouts,
      exercises: customExercises,
      bodyweights: bodyweights,
      foods: foods,
      settings: {
        for (final e in profile.extra.entries)
          if (backupSettingsKeys.contains(e.key)) e.key: e.value,
      },
    ),
  );

  String exportCsv() => workoutsToCsv(workouts, exercise);

  /// Doplní ze zálohy tréninky a vlastní cviky, které v zařízení chybí.
  /// Co už v zařízení je (i upravené po záloze), zůstane beze změny;
  /// nic se nemaže. Vrací počet doplněných tréninků.
  /// Neplatný soubor hodí [FormatException] s českou zprávou.
  Future<int> restoreBackup(String source) async {
    final backup = decodeBackup(source);
    final count = await _enqueue(() async {
      final haveWorkouts = {for (final w in workouts) w.id};
      final haveExercises = {for (final e in customExercises) e.id};
      final newWorkouts = [
        for (final w in backup.workouts)
          if (!haveWorkouts.contains(w.id)) w,
      ];
      final newExercises = [
        for (final e in backup.exercises)
          if (!haveExercises.contains(e.id)) e,
      ];
      // Nic místního se nepřepíše: ze zálohy se doplní jen chybějící
      // nastavení a programy, které tu ještě nejsou.
      final localPrograms = [
        ...profile.extra[ProfileKey.programs] as List? ?? const [],
      ];
      final localIds = {
        for (final e in localPrograms)
          if (e is Map) e['id'],
      };
      final backupPrograms = backup.settings[ProfileKey.programs];
      final nextProfile = profile.withExtra({
        for (final e in backup.settings.entries)
          if (e.key != 'programs' && !profile.extra.containsKey(e.key))
            e.key: e.value,
        if (backupPrograms is List)
          ProfileKey.programs: [
            ...localPrograms,
            for (final e in backupPrograms)
              if (e is Map && !localIds.contains(e['id'])) e,
          ],
      });
      final haveWeights = {for (final b in bodyweights) b.id};
      final newWeights = [
        for (final b in backup.bodyweights)
          if (!haveWeights.contains(b.id)) b,
      ];
      final haveFoods = {for (final f in foods) f.id};
      final newFoods = [
        for (final f in backup.foods)
          if (!haveFoods.contains(f.id)) f,
      ];
      final docs = <(String, Map<String, dynamic>)>[
        for (final f in newFoods) (Kinds.food, f.toJson()),
        for (final b in newWeights) (Kinds.bodyweight, b.toJson()),
        for (final e in newExercises) (Kinds.exercise, e.toJson()),
        for (final w in newWorkouts) (Kinds.workout, w.toJson()),
        (Kinds.profile, nextProfile.toJson()),
      ];
      for (final (kind, data) in docs) {
        if (kind == Kinds.profile) continue;
        final existing = await store.raw(data['id'] as String);
        if ((existing != null && existing['kind'] != kind) ||
            data['id'] == active?.id) {
          throw const FormatException(
            'Záloha obsahuje kolidující ID. Nic nebylo obnoveno.',
          );
        }
      }
      await store.putAll(docs);
      workouts = [...newWorkouts, ...workouts]
        ..sort((a, b) => b.date.compareTo(a.date));
      customExercises = [...newExercises, ...customExercises]
        ..sort((a, b) => a.name.compareTo(b.name));
      profile = nextProfile;
      bodyweights = [...newWeights, ...bodyweights]
        ..sort((a, b) => b.date.compareTo(a.date));
      foods = [...newFoods, ...foods]..sort(AppState._newestFood);
      return newWorkouts.length;
    });
    _changed();
    unawaited(syncReminders());
    return count;
  }

  /// Doplní tréninky z exportu Hevy. Už existující (stejný začátek a název)
  /// přeskočí, takže opakovaný import nic nezdvojí. Vrací počet přidaných.
  Future<int> importHevy(String source) async {
    final count = await _enqueue(() async {
      final parsed = parseHevyCsv(source, custom: customExercises);
      // Smazaný trénink se opakovaným importem nevrací.
      final deleted = <String>{
        for (final w in parsed.workouts)
          if ((await store.raw(w.id))?['deleted'] == 1) w.id,
      };
      final haveWorkouts = {for (final w in workouts) w.id, ...deleted};
      final haveExercises = {for (final e in customExercises) e.id};
      final newWorkouts = [
        for (final w in parsed.workouts)
          if (!haveWorkouts.contains(w.id)) w,
      ];
      final newExercises = [
        for (final e in parsed.newExercises)
          if (!haveExercises.contains(e.id)) e,
      ];
      await store.putAll([
        for (final e in newExercises) (Kinds.exercise, e.toJson()),
        for (final w in newWorkouts) (Kinds.workout, w.toJson()),
      ]);
      workouts = [...newWorkouts, ...workouts]
        ..sort((a, b) => b.date.compareTo(a.date));
      customExercises = [...newExercises, ...customExercises]
        ..sort((a, b) => a.name.compareTo(b.name));
      return newWorkouts.length;
    });
    _changed();
    unawaited(syncReminders());
    return count;
  }

  /// Smaže všechna data v zařízení včetně souhlasu (aplikace začne znovu).
  Future<void> wipeAll() async {
    await _enqueue(store.wipeLocal);
    profile = const Profile();
    workouts = [];
    active = null;
    customExercises = [];
    bodyweights = [];
    foods = [];
    _changed();
    if (notifier.supported) unawaited(notifier.cancelAll());
    // Budík pauzy má vlastní id, cancelAll ho nezruší.
    unawaited(syncRest());
  }
}

part of '../app_state.dart';

/// Aktivní trénink.
extension ActiveWorkoutOps on AppState {
  /// Zápis do úložiště ve frontě za předchozími (viz [AppState._writes]).
  Future<T> _enqueue<T>(Future<T> Function() write) {
    final previous = _writes;
    final next = previous == null
        ? Future<T>.sync(write)
        : previous.then((_) => write());
    final chain = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _writes = chain;
    // Doběhlá fronta se zahodí: další zápis pak nezávisí na zóně staré future.
    chain.whenComplete(() {
      if (identical(_writes, chain)) _writes = null;
    });
    return next;
  }

  /// Uloží aktuální stav rozepsaného tréninku.
  Future<void> saveActive() {
    final workout = active;
    if (workout == null) return _writes ?? Future.value();
    final json = workout.toJson();
    _activeRev++;
    _changed();
    return _enqueue(() => store.put(Kinds.workout, json));
  }

  /// Začne nový trénink, nebo vrátí rozepsaný.
  Future<Workout> startWorkout({String? name, DateTime? now}) async {
    if (_finishing != null) throw StateError('Počkej na uložení tréninku.');
    final existing = active;
    if (existing != null) return existing;
    final start = now ?? DateTime.now();
    _dayPick = null;
    active = Workout(
      id: newId(),
      name: name ?? 'Trénink – ${AppState._weekdays[start.weekday - 1]}',
      startedAt: start,
    );
    await saveActive();
    return active!;
  }

  /// Zopakuje minulý trénink: stejné cviky, hodnoty z posledního provedení.
  Future<Workout> repeatWorkout(Workout past) async {
    if (active != null) throw StateError('Nejdřív dokonči rozepsaný trénink.');
    final workout = await startWorkout(name: past.name);
    final ids = <String>[];
    for (final e in past.exercises) {
      if (!ids.contains(e.exerciseId)) ids.add(e.exerciseId);
    }
    for (final id in ids) {
      workout.exercises.add(_prefilled(id));
    }
    await saveActive();
    return workout;
  }

  /// Série předvyplněné z posledního provedení cviku (nedokončené).
  WorkoutExercise _prefilled(String exerciseId) {
    final last = lastSetsOf(exerciseId);
    return WorkoutExercise(
      id: newId(),
      exerciseId: exerciseId,
      sets: last.isEmpty
          ? [SetEntry()]
          : [for (final s in last) s.copy(done: false)],
    );
  }

  /// Stav odznaků (v mezipaměti, dokud se nezmění tréninky nebo cviky).
  /// Platí jen proto, že `workouts` i `customExercises` se při každé změně
  /// nahrazují novým seznamem; úprava na místě by mezipaměť nezneplatnila.
  List<BadgeState> get badgeStates {
    if (!identical(_badgesOf, workouts) ||
        !identical(_badgesExercises, customExercises)) {
      _badges = computeBadges(workouts, typeOf);
      _badgesOf = workouts;
      _badgesExercises = customExercises;
    }
    return _badges;
  }

  /// Odznaky odemčené daným tréninkem.
  List<BadgeState> badgesFrom(String workoutId) => [
    for (final b in badgeStates)
      if (b.workoutId == workoutId) b,
  ];

  /// Nejlepší výkony cviku z dokončených tréninků (v mezipaměti, dokud se
  /// nezmění tréninky nebo vlastní cviky, podle kterých se určí typ cviku).
  Map<RecordKind, PersonalRecord> recordsOf(String exerciseId) => memo(
    'records:$exerciseId',
    _historyDeps,
    () => allTimeRecords(workouts, exerciseId, typeOf(exerciseId)),
  );

  // Odvozené přehledy z historie: počítají se jednou, dokud se tréninky
  // nebo vlastní cviky nezmění (dřív při každém překreslení).
  Object get _historyDeps => (workouts, customExercises);

  /// Poslední rekordy (Domů, Pokrok, Cviky).
  List<PersonalRecord> recentRecordList() => memo(
    'recentRecords',
    _historyDeps,
    () => recentRecords(workouts, typeOf),
  );

  /// Nejčastěji cvičený cvik.
  String? mostTrained() =>
      memo('mostTrained', workouts, () => mostTrainedExercise(workouts));

  /// Křivka síly cviku.
  List<ProgressPoint> progressOf(String exerciseId) => memo(
    'progress:$exerciseId',
    _historyDeps,
    () => progressSeries(workouts, exerciseId, typeOf(exerciseId)),
  );

  /// Všechna provedení cviku, od nejstaršího.
  List<ExerciseSession> historyOf(String exerciseId) => memo(
    'history:$exerciseId',
    workouts,
    () => exerciseHistory(workouts, exerciseId),
  );

  /// Souhrn týdne, do kterého patří [now].
  WeekSummary weekSummaryAt(DateTime now) => memo('week', (
    _historyDeps,
    AppState._day(now),
  ), () => weekSummary(workouts, now, typeOf));

  /// Souhrn minulého týdne vůči [now].
  WeekSummary previousWeekAt(DateTime now) => memo('prevWeek', (
    _historyDeps,
    AppState._day(now),
  ), () => previousWeekSummary(workouts, now, typeOf));

  /// Počet rekordů v týdnu [now].
  int weekRecordsAt(DateTime now) => memo('weekRecords', (
    _historyDeps,
    AppState._day(now),
  ), () => weekRecordCount(workouts, now, typeOf));

  bool _isWeighted(SetEntry set) {
    for (final e in active?.exercises ?? const <WorkoutExercise>[]) {
      if (e.sets.any((s) => identical(s, set))) {
        return typeOf(e.exerciseId) == ExerciseType.weighted;
      }
    }
    return false;
  }

  /// Rekordy, které potvrzená série v aktivním tréninku právě drží.
  List<RecordKind> liveRecords(SetEntry set) {
    final workout = active;
    if (workout == null || !set.counts) return const [];
    String? exerciseId;
    for (final e in workout.exercises) {
      if (e.sets.any((s) => identical(s, set))) exerciseId = e.exerciseId;
    }
    if (exerciseId == null) return const [];
    return liveRecordKinds(
      set: set,
      sessionSets: [
        for (final e in workout.exercises)
          if (e.exerciseId == exerciseId) ...e.sets,
      ],
      before: recordsOf(exerciseId),
      type: typeOf(exerciseId),
    );
  }

  /// Série z posledního dokončeného provedení cviku (pro „minule“).
  List<SetEntry> lastSetsOf(String exerciseId) {
    final session = lastPerformance(workouts, exerciseId);
    if (session == null) return const [];
    return [
      for (final e in session.workout.exercises)
        if (e.exerciseId == exerciseId) ...e.sets.where((s) => s.done),
    ];
  }

  Future<WorkoutExercise> addExercise(String exerciseId) async {
    final workout = active ?? await startWorkout();
    final entry = _prefilled(exerciseId);
    workout.exercises.add(entry);
    await saveActive();
    return entry;
  }

  Future<void> replaceExercise(WorkoutExercise entry, String exerciseId) {
    final fresh = _prefilled(exerciseId);
    entry
      ..exerciseId = exerciseId
      ..sets = fresh.sets
      // Návrh kouče patřil původnímu cviku.
      ..extra.remove(coachKey);
    return saveActive();
  }

  /// Přidá rozcvičovací série podle první pracovní váhy cviku. Dřívější
  /// nepotvrzené rozcvičky nahradí. Vrací počet přidaných sérií; `null`,
  /// když už je nějaká rozcvička potvrzená nebo chybí pracovní váha.
  Future<int?> addWarmups(WorkoutExercise entry) async {
    if (entry.sets.any((s) => s.warmup && s.done)) return null;
    final working = entry.sets.where((s) => !s.warmup && s.weight > 0);
    if (working.isEmpty) return null;
    final plan = warmupPlan(working.first.weight);
    if (plan.isEmpty) return 0;
    entry.sets = [
      for (final w in plan)
        SetEntry(weight: w.weight, reps: w.reps, warmup: true),
      ...entry.sets.where((s) => !s.warmup),
    ];
    await saveActive();
    return plan.length;
  }

  Future<void> removeExercise(WorkoutExercise entry) {
    active?.exercises.remove(entry);
    return saveActive();
  }

  /// Posune cvik v tréninku o [delta] míst (záporně = nahoru).
  Future<void> moveExercise(WorkoutExercise entry, int delta) {
    final list = active?.exercises;
    if (list == null) return Future.value();
    final from = list.indexOf(entry);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= list.length) return Future.value();
    list
      ..removeAt(from)
      ..insert(to, entry);
    return saveActive();
  }

  /// Přesune cvik tažením z indexu [from] na výsledný index [to].
  Future<void> reorderExercise(int from, int to) {
    final list = active?.exercises;
    if (list == null || from < 0 || from >= list.length) {
      return Future.value();
    }
    final target = to.clamp(0, list.length - 1);
    if (target == from) return Future.value();
    list.insert(target, list.removeAt(from));
    return saveActive();
  }

  /// Hodnoty „minule" pro série cviku (stejný druh a pořadí v něm).
  List<SetEntry?> previousFor(WorkoutExercise entry) =>
      previousSets(entry.sets, lastSetsOf(entry.exerciseId));

  /// Další pracovní série: hodnoty z minula na stejné pozici, jinak kopie
  /// poslední pracovní série.
  Future<SetEntry> addSet(WorkoutExercise entry) async {
    final set = nextWorkingSet(entry.sets, lastSetsOf(entry.exerciseId));
    entry.sets.add(set);
    await saveActive();
    return set;
  }

  /// Smaže sérii a vrátí její pozici (pro „Vrátit"), -1 když tam nebyla.
  Future<int> removeSet(WorkoutExercise entry, SetEntry set) async {
    final index = entry.sets.indexOf(set);
    if (index < 0) return index;
    entry.sets.removeAt(index);
    await saveActive();
    return index;
  }

  /// Vrátí smazanou sérii na původní místo. [sets] je seznam, ze kterého
  /// se mazalo: po nahrazení cviku, jeho odebrání nebo dokončení tréninku
  /// se nic nevrací (vrací `false`).
  Future<bool> restoreSet(
    WorkoutExercise entry,
    SetEntry set,
    int index, {
    required List<SetEntry> sets,
  }) async {
    if (!(active?.exercises.contains(entry) ?? false) ||
        !identical(entry.sets, sets) ||
        sets.contains(set)) {
      return false;
    }
    sets.insert(index.clamp(0, sets.length), set);
    await saveActive();
    return true;
  }

  /// Další nepotvrzené pracovní série téhož cviku, které mají stejné
  /// hodnoty jako [set]. Volá se při otevření úprav, než se cokoli změní.
  List<SetEntry> followersOf(SetEntry set) {
    if (set.warmup) return const [];
    final entry = active?.exercises
        .where((e) => e.sets.any((s) => identical(s, set)))
        .firstOrNull;
    if (entry == null) return const [];
    final start = entry.sets.indexWhere((s) => identical(s, set));
    return [
      for (final s in entry.sets.skip(start + 1))
        if (!s.done &&
            !s.warmup &&
            s.weight == set.weight &&
            s.reps == set.reps)
          s,
    ];
  }

  /// Přenese váhu a opakování z [set] na [followers] (z [followersOf]
  /// při otevření úprav). Mezitím potvrzené nebo smazané série vynechá.
  /// Vrací počet změněných sérií; uložení je na volajícím.
  int carryForward(SetEntry set, List<SetEntry> followers) {
    final sets = active?.exercises
        .where((e) => e.sets.any((s) => identical(s, set)))
        .firstOrNull
        ?.sets;
    if (sets == null) return 0;
    var changed = 0;
    for (final s in followers) {
      if (s.done || s.warmup || !sets.any((x) => identical(x, s))) continue;
      if (s.weight == set.weight && s.reps == set.reps) continue;
      s
        ..weight = set.weight
        ..reps = set.reps;
      changed++;
    }
    if (changed > 0) {
      _activeRev++;
      _changed();
    }
    return changed;
  }

  /// Označí sérii jako hotovou (nebo zpět). Vrací chybovou hlášku,
  /// když se série nedá potvrdit. Potvrzení spustí pauzu.

  Future<String?> toggleDone(SetEntry set, {DateTime? now}) async {
    if (!set.done) {
      if (set.reps <= 0) return 'Zadej počet opakování.';
      if (set.weight < 0 || !set.weight.isFinite) return 'Neplatná váha.';
      if (!set.warmup && set.weight == 0 && _isWeighted(set)) {
        return 'Zadej váhu v kg.';
      }
    }
    set.done = !set.done;
    if (set.done) {
      final id = active?.exercises
          .where((e) => e.sets.contains(set))
          .firstOrNull
          ?.exerciseId;
      _setRestEnd((now ?? DateTime.now()).add(Duration(seconds: restFor(id))));
    }
    await saveActive();
    await syncRest();
    return null;
  }
}

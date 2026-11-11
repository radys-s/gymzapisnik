part of '../app_state.dart';

/// Split a progrese.
extension ProgramOps on AppState {
  /// Zvolený program. Hotová šablona se přizpůsobí doporučenému počtu
  /// cviků z dotazníku „Tvůj plán“; vlastní program zůstává, jak je.
  SplitTemplate? get split {
    if (!identical(_splitOf, profile)) {
      final base = findSplit(profile.splitId, customPrograms);
      _split = base == null ? null : fitted(base);
      _splitOf = profile;
    }
    return _split;
  }

  /// Hotový program s dny upravenými na doporučený počet cviků
  /// z dotazníku. Vlastní programy zůstávají, jak si je uživatel složil.
  SplitTemplate fitted(SplitTemplate base) {
    final answers = planAnswers;
    if (base.custom || answers == null) return base;
    final count = recommendPlan(answers).exercises;
    return base.copyWith(
      days: [
        for (final d in base.days) personalizeDay(fitDay(d, count), answers),
      ],
    );
  }

  /// Odpovědi z dotazníku „Tvůj plán“; `null` = ještě nevyplněný.
  PlanAnswers? get planAnswers =>
      PlanAnswers.tryParse(profile.extra[ProfileKey.plan]);

  /// Uloží odpovědi a zapne doporučený program, počet tréninků týdně
  /// a pauzu podle cíle. Bez [answers] (doporučení bez dotazníku) zapne
  /// jen výchozí doporučený program a odpovědi neuloží.
  Future<PlanRecommendation> applyPlan(PlanAnswers? answers) async {
    final r = recommendPlan(answers ?? const PlanAnswers());
    await _updateProfile((p) {
      // Vybrané dny zůstanou, když jich je tolik, kolik plán chce.
      final days = p.trainingDays;
      return p.withExtra({
        ProfileKey.plan: ?answers?.toJson(),
        ProfileKey.planDraft: null,
        ProfileKey.split: r.splitId,
        ProfileKey.weekGoal: r.perWeek,
        if (days != null && days.length != r.perWeek)
          ProfileKey.trainingDays: null,
        ProfileKey.restSeconds: r.restSeconds,
      });
    });
    unawaited(syncReminders());
    return r;
  }

  /// Moje posilovna: typ a stroje, které chybí nebo navíc jsou. Program
  /// ani počet tréninků nemění, jen cviky v hotovém plánu se přizpůsobí.
  Future<void> setGym({
    TrainingPlace? place,
    Set<String>? missing,
    Set<String>? present,
  }) async {
    final base = planAnswers ?? const PlanAnswers();
    final next = base.copyWith(
      place: place,
      missing: missing,
      present: present,
    );
    await _updateProfile((p) => p.withExtra({ProfileKey.plan: next.toJson()}));
  }

  /// Jestli cvik v téhle posilovně jde (bez dotazníku vše).
  bool gymHas(String exerciseId) =>
      !(planAnswers?.unavailable.contains(exerciseId) ?? false);

  /// Přepne, jestli posilovna stroj na cvik [id] má.
  Future<void> toggleGymExercise(String id) async {
    final a = planAnswers ?? const PlanAnswers();
    final missing = {...a.missing};
    final present = {...a.present};
    final has = !a.unavailable.contains(id);
    if (a.place.presetMissing.contains(id)) {
      has ? present.remove(id) : present.add(id);
      missing.remove(id);
    } else {
      has ? missing.add(id) : missing.remove(id);
    }
    await setGym(missing: missing, present: present);
  }

  /// Stroje z fotky: cviky, které posilovna určitě má.
  Future<void> markGymHas(Iterable<String> ids) async {
    final a = planAnswers ?? const PlanAnswers();
    final missing = {...a.missing}..removeAll(ids);
    final present = {
      ...a.present,
      for (final id in ids)
        if (a.place.presetMissing.contains(id)) id,
    };
    await setGym(missing: missing, present: present);
  }

  /// Vlastní programy (uložené v profilu, jdou i do zálohy).
  List<SplitTemplate> get customPrograms {
    if (!identical(_programsOf, profile)) {
      _programsOf = profile;
      final raw = profile.extra[ProfileKey.programs];
      _programs = [
        if (raw is List)
          for (final json in raw) ?SplitTemplate.tryCustom(json),
      ];
    }
    return _programs;
  }

  Future<void> setSplit(String? id) async {
    await _updateProfile((p) => p.withExtra({ProfileKey.split: id}));
    unawaited(syncReminders());
  }

  /// Uloží vlastní program (nový dostane ID). Vrací uložený program,
  /// nebo hodí [ArgumentError] s českou zprávou.
  Future<SplitTemplate> saveProgram(
    SplitTemplate program, {
    bool activate = false,
  }) async {
    final cleaned = program.copyWith(
      id: program.id.startsWith(customProgramPrefix)
          ? program.id
          : '$customProgramPrefix${newId()}',
      name: program.name.trim(),
      custom: true,
      // Vlastní program se cvičí dokola: doporučení = počet dnů.
      perWeek: program.days.length.clamp(1, 7),
      days: [for (final d in program.days) d.copyWith(name: d.name.trim())],
    );
    final error = programError(cleaned);
    if (error != null) throw ArgumentError(error);
    await _updateProfile((p) {
      // Ostatní programy zůstanou tak, jak jsou uložené (i ty, které
      // novější verze neumí přečíst), aby se uložením jednoho neztratily.
      final list = [...p.extra[ProfileKey.programs] as List? ?? const []];
      final at = list.indexWhere((e) => e is Map && e['id'] == cleaned.id);
      if (at >= 0) {
        list[at] = cleaned.toJson();
      } else {
        if (list.length >= maxCustomPrograms) {
          throw ArgumentError(
            'Vlastních programů může být nejvýš $maxCustomPrograms.',
          );
        }
        list.add(cleaned.toJson());
      }
      return p.withExtra({
        ProfileKey.programs: list,
        if (activate) ProfileKey.split: cleaned.id,
      });
    });
    unawaited(syncReminders());
    return cleaned;
  }

  /// Smaže vlastní program; byl-li zvolený, přejde na volné tréninky.
  Future<void> deleteProgram(String id) async {
    await _updateProfile((p) {
      final list = [
        for (final json in p.extra[ProfileKey.programs] as List? ?? const [])
          if (json is Map && json['id'] != id) json,
      ];
      return p.withExtra({
        ProfileKey.programs: list.isEmpty ? null : list,
        if (p.splitId == id) ProfileKey.split: null,
      });
    });
    unawaited(syncReminders());
  }

  /// Frekvence: kolikrát týdně a volitelně ve které dny. Se zvolenými dny
  /// je cíl jejich počet; `null` cíl = podle programu.
  Future<void> setFrequency({int? perWeek, List<int>? days}) async {
    final picked = days == null || days.isEmpty
        ? null
        : ({for (final d in days) d.clamp(1, 7)}.toList()..sort());
    await _updateProfile(
      (p) => p.withExtra({
        ProfileKey.weekGoal: picked?.length ?? perWeek?.clamp(1, 7),
        ProfileKey.trainingDays: picked,
      }),
    );
    unawaited(syncReminders());
  }

  /// Přidá nebo odebere den tréninku (1 = pondělí). Čte aktuální profil
  /// až ve frontě zápisů, takže rychlá klepnutí se nepřepíšou. Bez dnů
  /// se cíl vrátí na počet podle programu.
  Future<void> toggleTrainingDay(int day) async {
    await _updateProfile((p) {
      final days = [...?p.trainingDays];
      if (!days.remove(day)) days.add(day.clamp(1, 7));
      days.sort();
      return p.withExtra({
        ProfileKey.weekGoal: days.isEmpty ? null : days.length,
        ProfileKey.trainingDays: days.isEmpty ? null : days,
      });
    });
    unawaited(syncReminders());
  }

  /// Označí profil jako Pro (až bude hotová platba, volá se po nákupu).
  Future<void> setPro(bool value) async {
    await _updateProfile(
      (p) => p.withExtra({ProfileKey.pro: value ? true : null}),
    );
  }

  /// Týdenní cíl tréninků: vlastní, jinak podle splitu, jinak 3.
  int get weekGoal => profile.weekGoal ?? split?.perWeek ?? 3;

  /// Čas připomínky (minuty od půlnoci) nebo `null` = vypnout. Při zapnutí
  /// se zeptá na povolení; vrací `false`, když ho uživatel odmítl.
  Future<bool> setReminder(int? minutes) async {
    if (minutes != null && !await notifier.requestPermission()) {
      return false;
    }
    await _updateProfile(
      (p) => p.withExtra({ProfileKey.reminder: minutes?.clamp(0, 1439)}),
    );
    await syncReminders();
    return true;
  }

  /// Přepočítá naplánovaná oznámení podle tréninků a týdenního cíle.
  /// Chyba plánování nikdy nesmí shodit zápis tréninku.
  Future<void> syncReminders({DateTime? now}) async {
    if (!notifier.supported) return;
    try {
      final minutes = profile.reminderMinutes;
      if (minutes == null) {
        await notifier.cancelAll();
        return;
      }
      await notifier.schedule(
        planReminders(
          now: now ?? DateTime.now(),
          hour: minutes ~/ 60,
          minute: minutes % 60,
          goal: weekGoal,
          finished: workouts,
          trainingDays: profile.trainingDays,
        ),
      );
    } catch (e) {
      debugPrint('Připomínky se nepodařilo naplánovat: $e');
    }
  }

  bool get backupDue {
    final saved = profile.extra[ProfileKey.backupCount];
    final at = saved is num ? saved.toInt() : 0;
    return workouts.length - at >= AppState.backupEvery;
  }

  /// Zapamatuje, že záloha právě vznikla.
  Future<void> markBackedUp() async {
    await _updateProfile(
      (p) => p.withExtra({ProfileKey.backupCount: workouts.length}),
    );
  }

  /// Týdenní cíl bez pevných dnů (`null` = podle programu).
  Future<void> setWeekGoal(int? goal) => setFrequency(perWeek: goal);

  /// Dnešní mise podle týdenního cíle a odcvičených tréninků.
  Mission mission([DateTime? now]) => todayMission(
    goal: weekGoal,
    finished: [for (final w in workouts) w.date],
    now: now ?? DateTime.now(),
    startedAt: profile.consentAt?.toLocal(),
    trainingDays: profile.trainingDays,
  );

  /// Týdny v řadě se splněným cílem.
  Streak streak([DateTime? now]) => computeStreak(
    goal: weekGoal,
    finished: [for (final w in workouts) w.date],
    now: now ?? DateTime.now(),
  );

  /// Den splitu na řadě (po posledním odcvičeném dni).
  int get nextSplitDay {
    final s = split;
    return s == null ? 0 : nextDayIndex(s, workouts);
  }

  /// Den, který je dnes na řadě: ručně zvolený na hlavní kartě, jinak
  /// další v pořadí. Stejný den ukazuje hlavní karta i trenér.
  int get todaySplitDay {
    final s = split;
    if (s == null || s.days.isEmpty) return 0;
    if (_dayPick case (final id, final day) when id == s.id) {
      return day % s.days.length;
    }
    return nextSplitDay;
  }

  SplitDay? get todayDay {
    final s = split;
    return s == null || s.days.isEmpty ? null : s.days[todaySplitDay];
  }

  /// Zvolí jiný den programu na dnešek (`null` = zpět na den na řadě).
  void pickSplitDay(int? day) {
    final s = split;
    _dayPick = s == null || day == null ? null : (s.id, day);
    _changed();
  }

  /// Návrh váhy a opakování pro každý cvik dne.
  ///
  /// Cvik dělaný poprvé dostane startovní váhu vždy; další návrhy váhy
  /// jsou v Pro, bez něj zůstane jen rozsah z plánu.
  List<(PlannedExercise, Suggestion)> plan(SplitDay day) => [
    for (final p in day.exercises)
      (p, _suggestFor(p, exerciseHistory(workouts, p.exerciseId))),
  ];

  /// Návrh na příští provedení cviku: rozsah z programu, když ho program
  /// má, jinak 3 × 8–12.
  Suggestion nextSuggestion(String exerciseId) {
    final planned =
        split?.days
            .expand((d) => d.exercises)
            .where((p) => p.exerciseId == exerciseId)
            .firstOrNull ??
        PlannedExercise(exerciseId, sets: 3, repMin: 8, repMax: 12);
    return _suggestFor(planned, exerciseHistory(workouts, exerciseId));
  }

  /// Startovní váha poprvé (i bez Pro), potom návrh kouče.
  Suggestion _suggestFor(PlannedExercise p, List<ExerciseSession> history) =>
      has(ProFeature.coach) || history.isEmpty
      ? suggest(
          p,
          typeOf(p.exerciseId),
          history,
          start: startLoad(
            p.exerciseId,
            planAnswers?.level ?? PlanLevel.beginner,
          ),
          proteinLow: proteinLow(proteinWeek()),
        )
      : Suggestion(
          kind: SuggestionKind.start,
          weight: 0,
          reps: p.repMin,
          sets: p.sets,
          reason: 'Návrh váhy od kouče je součástí Pro.',
        );

  /// Začne trénink podle dne splitu s předvyplněnými návrhy.
  Future<Workout> startSplitDay(int dayIndex, {DateTime? now}) async {
    final s = split;
    if (s == null) throw StateError('Není zvolený split.');
    if (active != null) throw StateError('Nejdřív dokonči rozepsaný trénink.');
    final index = dayIndex % s.days.length;
    final day = s.days[index];
    final workout = await startWorkout(name: day.name, now: now);
    workout.extra
      ..['split'] = s.id
      ..['splitDay'] = index;
    await _fillPlanned(workout, day);
    return workout;
  }

  /// Začne trénink sestavený mimo program (výběr partií a počtu cviků).
  Future<Workout> startPlanned(SplitDay day, {DateTime? now}) async {
    if (active != null) throw StateError('Nejdřív dokonči rozepsaný trénink.');
    if (day.exercises.isEmpty) throw StateError('Trénink nemá žádný cvik.');
    final workout = await startWorkout(name: day.name, now: now);
    await _fillPlanned(workout, day);
    return workout;
  }

  Future<void> _fillPlanned(Workout workout, SplitDay day) async {
    for (final (p, suggestion) in plan(day)) {
      workout.exercises.add(
        WorkoutExercise(
          id: newId(),
          exerciseId: p.exerciseId,
          sets: suggestion.toSets(),
          extra: {coachKey: suggestion.toJson()},
        ),
      );
    }
    await saveActive();
  }
}

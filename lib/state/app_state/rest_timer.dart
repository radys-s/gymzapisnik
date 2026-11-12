part of '../app_state.dart';

/// Pauza mezi sériemi.
extension RestTimerOps on AppState {
  /// Konec pauzy jako časové razítko: odpočet sedí i po uspání nebo
  /// zavření aplikace. `null` = žádná pauza.
  DateTime? get restEndsAt {
    final v = active?.extra[AppState._restKey];
    return v is String ? DateTime.tryParse(v)?.toLocal() : null;
  }

  void _setRestEnd(DateTime? end) {
    final workout = active;
    if (workout == null) return;
    if (end == null) {
      workout.extra.remove(AppState._restKey);
    } else {
      workout.extra[AppState._restKey] = end.toUtc().toIso8601String();
    }
  }

  /// Prodlouží nebo zkrátí běžící pauzu; pod nulou ji ukončí.
  Future<void> adjustRest(Duration delta, {DateTime? now}) async {
    final end = restEndsAt;
    if (end == null) return;
    final next = end.add(delta);
    _setRestEnd(next.isAfter(now ?? DateTime.now()) ? next : null);
    await saveActive();
    await syncRest();
  }

  Future<void> skipRest() async {
    if (restEndsAt == null) return;
    _setRestEnd(null);
    await saveActive();
    await syncRest();
  }

  bool get restAlerts => profile.extra[ProfileKey.restAlerts] == true;

  Future<bool> setRestAlerts(bool enabled) async {
    if (notifier is! RestNotifier) return false;
    if (enabled && !await notifier.requestPermission()) return false;
    await _updateProfile(
      (p) => p.withExtra({ProfileKey.restAlerts: enabled ? true : null}),
    );
    await syncRest();
    return true;
  }

  /// Vyhodnotit poslední stav až ve frontě, aby stará pauza nepřepsala
  /// zrušení při dokončení tréninku. Chyba oznámení neblokuje zápis série.
  Future<void> syncRest() {
    final rest = notifier;
    if (rest is! RestNotifier) return Future.value();
    Future<void> update() async {
      try {
        final end = restEndsAt;
        if (restAlerts && end != null && end.isAfter(DateTime.now())) {
          await (rest as RestNotifier).scheduleRest(end);
        } else {
          await (rest as RestNotifier).cancelRest();
        }
      } catch (e) {
        debugPrint('Upozornění na pauzu se nepodařilo naplánovat: $e');
      }
    }

    final next = _restUpdates == null
        ? update()
        : _restUpdates!.then((_) => update());
    _restUpdates = next;
    next.whenComplete(() {
      if (identical(_restUpdates, next)) _restUpdates = null;
    });
    return next;
  }

  Future<void> toggleWarmup(SetEntry set) => setWarmup(set, !set.warmup);

  /// Nastaví druh série (rozcvička / pracovní).
  Future<void> setWarmup(SetEntry set, bool warmup) {
    if (set.warmup == warmup && set.kind == SetKind.normal) {
      return Future.value();
    }
    set
      ..kind = SetKind.normal
      ..warmup = warmup;
    return saveActive();
  }

  /// Drop série nebo do selhání; pracovní série zůstává pracovní.
  Future<void> setKind(SetEntry set, SetKind kind) {
    if (!set.warmup && set.kind == kind) return Future.value();
    set
      ..warmup = false
      ..kind = kind;
    return saveActive();
  }

  /// Dokončí trénink: uloží jen potvrzené série a cviky, které nějakou mají.
  /// Vrací dokončený trénink, nebo chybovou hlášku.
  Future<({Workout? workout, String? error})> finishActive({DateTime? now}) {
    final pending = _finishing;
    if (pending != null) return pending;
    final finishing = _finishActive(now: now);
    _finishing = finishing;
    return finishing.whenComplete(() => _finishing = null);
  }

  Future<({Workout? workout, String? error})> _finishActive({
    DateTime? now,
  }) async {
    final workout = active;
    if (workout == null) return (workout: null, error: 'Žádný trénink.');
    final done = workout.copy()..extra.remove(AppState._restKey);
    done.exercises = [
      for (final e in done.exercises)
        if (e.sets.any((s) => s.done && s.reps > 0))
          e..sets = e.sets.where((s) => s.done && s.reps > 0).toList(),
    ];
    if (!done.exercises.any((e) => e.countedSets.isNotEmpty)) {
      return (workout: null, error: 'Potvrď aspoň jednu pracovní sérii.');
    }
    final finished = Workout.fromJson({
      ...done.toJson(),
      'id': completedWorkoutId(workout.id),
      'finishedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
    });
    // Aktivní trénink se odpojí hned, aby opožděné uložení z UI
    // (např. psaní do pole těsně před dokončením) ho nevrátilo zpět.
    active = null;
    try {
      await _enqueue(
        () => store.replace(
          removeId: workout.id,
          kind: Kinds.workout,
          data: finished.toJson(),
        ),
      );
    } catch (_) {
      active = workout;
      _changed();
      return (
        workout: null,
        error: 'Trénink se nepodařilo uložit. Zkus dokončení znovu. Pokud chyba trvá, aplikaci nezavírej.',
      );
    }
    workouts = [finished, ...workouts.where((w) => w.id != finished.id)]
      ..sort((a, b) => b.date.compareTo(a.date));
    _changed();
    unawaited(syncReminders());
    unawaited(syncRest());
    return (workout: finished, error: null);
  }

  Future<void> discardActive() async {
    final workout = active;
    if (workout == null) return;
    active = null;
    try {
      await _enqueue(() => store.remove(workout.id));
    } catch (_) {
      active = workout;
      rethrow;
    }
    _changed();
    await syncRest();
  }
}

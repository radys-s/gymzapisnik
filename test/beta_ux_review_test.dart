import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/notify/notifier.dart';
import 'package:gymzapisnik/coach/reminders.dart';
import 'package:gymzapisnik/domain/nutrition.dart';

class RecordingNotifier implements Notifier, RestNotifier {
  bool allow = true;
  DateTime? rest;
  @override
  bool get supported => true;
  @override
  Future<bool> requestPermission() async => allow;
  @override
  Future<void> schedule(List<Reminder> reminders) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> scheduleRest(DateTime end) async => rest = end;
  @override
  Future<void> cancelRest() async => rest = null;
}

void main() {
  late AppState state;
  setUp(() async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    state = AppState(LocalStore(db));
    await state.load();
  });

  test(
    'concurrent pantry, appearance and AI consent retain every change',
    () async {
      await Future.wait([
        state.setPreferences(accent: 'lagoon'),
        state.savePantry([const PantryItem('Tvaroh', amount: 250, unit: 'g')]),
        state.acceptAiNotice(),
      ]);
      expect(state.profile.accent, 'lagoon');
      expect(state.pantry.single.name, 'Tvaroh');
      expect(state.profile.aiNoticeAccepted, isTrue);
      await state.load();
      expect(state.profile.accent, 'lagoon');
      expect(state.pantry.single.name, 'Tvaroh');
    },
  );

  test('concurrent AI requests use one persisted installation ID', () async {
    final ids = await Future.wait([state.installId(), state.installId()]);
    expect(ids.toSet(), hasLength(1));
    await state.load();
    expect(await state.installId(), ids.first);
  });

  test('rapid tab changes persist the last tap alongside appearance', () async {
    await Future.wait([
      state.setLastTab(1),
      state.setPreferences(accent: 'sunset'),
      state.setLastTab(0),
    ]);
    await state.load();
    expect(state.profile.lastTab, 0);
    expect(state.profile.accent, 'sunset');
  });

  test('pantry merge replaces a confirmed quantity without duplicates or losing known amounts', () {
    final merged = mergePantry(
      const [
        PantryItem('Vejce', amount: 6, unit: 'ks'),
        PantryItem('Mléko', amount: 500, unit: 'ml'),
      ],
      const [PantryItem(' vejce ', amount: 2, unit: 'ks'), PantryItem('mléko')],
    );
    expect(merged, hasLength(2));
    expect(merged.first.amount, 2);
    expect(merged.last.amount, 500);
  });

  test(
    'pantry selection and last meal ideas survive reopening storage',
    () async {
      await state.savePantrySelection({'vejce'}, 10);
      await state.saveMealIdeas(const [
        MealIdea(
          title: 'Jídlo',
          minutes: 10,
          ingredients: [PantryItem('neznámá potravina')],
          steps: ['Připrav.'],
          estimate: Nutrition(protein: 20),
          source: EstimateSource.ai,
        ),
      ]);
      final restarted = AppState(state.store);
      await restarted.load();
      expect(restarted.pantryExcluded, {'vejce'});
      expect(restarted.pantryMinutes, 10);
      expect(restarted.savedMealIdeas.single.title, 'Jídlo');
      expect(restarted.savedMealIdeas.single.estimate.kcal, isNull);
    },
  );

  test('rest permission, adjustment, restart and finish keep only the current alarm', () async {
    final notifier = RecordingNotifier();
    final mobile = AppState(state.store, notifier: notifier);
    await mobile.load();
    notifier.allow = false;
    expect(await mobile.setRestAlerts(true), isFalse);
    expect(mobile.restAlerts, isFalse);
    notifier.allow = true;
    expect(await mobile.setRestAlerts(true), isTrue);
    await mobile.startWorkout();
    final entry = await mobile.addExercise('bench_press');
    entry.sets.first
      ..weight = 50
      ..reps = 8;
    await mobile.toggleDone(entry.sets.first);
    expect(notifier.rest, mobile.restEndsAt);
    await mobile.adjustRest(const Duration(seconds: 15));
    expect(notifier.rest, mobile.restEndsAt);
    await mobile.load();
    await mobile.syncRest();
    expect(notifier.rest, mobile.restEndsAt);
    await mobile.finishActive();
    await mobile.syncRest();
    expect(notifier.rest, isNull);
    expect(mobile.workouts.single.exercises.single.sets.single.done, isTrue);
  });

  test('wiping all data cancels a running rest alarm', () async {
    final notifier = RecordingNotifier()..allow = true;
    final mobile = AppState(state.store, notifier: notifier);
    await mobile.load();
    await mobile.setRestAlerts(true);
    await mobile.startWorkout();
    final entry = await mobile.addExercise('bench_press');
    entry.sets.first
      ..weight = 50
      ..reps = 8;
    await mobile.toggleDone(entry.sets.first);
    expect(notifier.rest, isNotNull);
    await mobile.wipeAll();
    await mobile.syncRest();
    expect(notifier.rest, isNull);
  });
}

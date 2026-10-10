import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/missions.dart';
import 'package:gymzapisnik/coach/reminders.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/state/app_state.dart';

Future<AppState> newState() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await state.load();
  await state.acceptConsent(adult: true, guardianConsent: false);
  return state;
}

SplitTemplate arms({String id = ''}) => SplitTemplate(
  id: id,
  name: '  Ruce a ramena ',
  description: '',
  perWeek: 5,
  days: [
    dayFromFocuses(['triceps', 'shoulders']),
    const SplitDay(' Nohy ', [PlannedExercise('squat', sets: 5, repMin: 5)]),
  ],
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('program model', () {
    test('every focus exercise exists in the catalog', () {
      for (final f in dayFocuses) {
        for (final e in f.exercises) {
          expect(
            findExercise(e.exerciseId, const []),
            isNotNull,
            reason: '${f.id}: ${e.exerciseId}',
          );
        }
      }
    });

    test('shoulders and triceps make one day in canonical order', () {
      final day = dayFromFocuses(['triceps', 'shoulders']);
      expect(day.name, 'Ramena a triceps');
      expect(day.exercises, hasLength(6));
      expect(day.exercises.first.exerciseId, 'overhead_press');
      expect(dayFromFocuses(['chest']).exercises, hasLength(5));
      expect(
        dayFromFocuses(['chest', 'back', 'biceps']).name,
        'Hrudník, záda a biceps',
      );
      expect(dayFromFocuses(const []).exercises, isEmpty);
      final many = dayFromFocuses([for (final f in dayFocuses) f.id]);
      expect(many.name, 'Hrudník a 8 další');
      expect(many.name.length, lessThanOrEqualTo(maxNameLength));
    });

    test('json round trip and custom parsing', () {
      final p = arms(id: 'custom_1');
      final back = SplitTemplate.tryCustom(jsonDecode(jsonEncode(p.toJson())));
      expect(back, isNotNull);
      expect(back!.custom, isTrue);
      expect(back.days[1].exercises.single.sets, 5);
      expect(back.days[1].exercises.single.repMin, 5);
      // Bez předpony by se mohl potkat s hotovou šablonou.
      expect(SplitTemplate.tryCustom(arms(id: 'ppl').toJson()), isNull);
      expect(SplitTemplate.tryCustom({'id': 'custom_x'}), isNull);
      expect(SplitTemplate.tryCustom('x'), isNull);
    });

    test('validation explains problems in Czech', () {
      expect(programError(arms(id: 'custom_1')), isNull);
      expect(programError(arms().copyWith(name: ' ')), 'Pojmenuj program.');
      expect(
        programError(arms().copyWith(days: const [])),
        'Přidej aspoň jeden den.',
      );
      expect(
        programError(arms().copyWith(days: const [SplitDay('Prázdný', [])])),
        'Den „Prázdný“ nemá žádný cvik.',
      );
      expect(
        programError(
          arms().copyWith(
            days: const [
              SplitDay('A', [PlannedExercise('squat', repMin: 12, repMax: 8)]),
            ],
          ),
        ),
        isNotNull,
      );
      expect(programSummary(arms()), '2 dny · 7 cviků');
    });
  });

  group('state', () {
    test('save, activate, edit and delete a custom program', () async {
      final state = await newState();
      final saved = await state.saveProgram(arms(), activate: true);
      expect(saved.id, startsWith(customProgramPrefix));
      expect(saved.name, 'Ruce a ramena');
      expect(saved.days[1].name, 'Nohy');
      expect(saved.perWeek, 2); // vlastní = počet dnů
      expect(state.split?.id, saved.id);
      expect(
        state.plan(state.split!.day(0)).first.$1.exerciseId,
        'overhead_press',
      );

      await state.saveProgram(saved.copyWith(name: 'Ruce'));
      expect(state.customPrograms.single.name, 'Ruce');

      // Po restartu zůstane program i jeho volba.
      final reloaded = AppState(state.store);
      await reloaded.load();
      expect(reloaded.split?.name, 'Ruce');

      await state.deleteProgram(saved.id);
      expect(state.customPrograms, isEmpty);
      expect(state.split, isNull);
    });

    test('invalid program is refused', () async {
      final state = await newState();
      await expectLater(
        state.saveProgram(arms().copyWith(days: const [])),
        throwsA(isA<ArgumentError>()),
      );
      expect(state.customPrograms, isEmpty);
    });

    test('frequency with and without weekdays', () async {
      final state = await newState();
      await state.setFrequency(days: [5, 1, 3, 3]);
      expect(state.profile.trainingDays, [1, 3, 5]);
      expect(state.weekGoal, 3);

      await state.setFrequency(perWeek: 4);
      expect(state.profile.trainingDays, isNull);
      expect(state.weekGoal, 4);

      await state.setFrequency(days: [2, 4]);
      await state.setWeekGoal(2);
      expect(state.profile.trainingDays, isNull);
    });

    test('quick day toggles do not overwrite each other', () async {
      final state = await newState();
      await Future.wait([
        state.toggleTrainingDay(1),
        state.toggleTrainingDay(3),
        state.toggleTrainingDay(5),
      ]);
      expect(state.profile.trainingDays, [1, 3, 5]);
      expect(state.weekGoal, 3);
      await Future.wait([
        for (final d in [1, 3, 5]) state.toggleTrainingDay(d),
      ]);
      expect(state.profile.trainingDays, isNull);
      expect(state.profile.weekGoal, isNull);
    });

    test('backup carries programs and training days', () async {
      final source = await newState();
      final saved = await source.saveProgram(arms(), activate: true);
      await source.setFrequency(days: [2, 4, 6]);

      final target = await newState();
      await target.restoreBackup(source.exportBackup());
      expect(target.split?.id, saved.id);
      expect(target.customPrograms.single.days, hasLength(2));
      expect(target.profile.trainingDays, [2, 4, 6]);
    });

    test('backup with a broken program or day is rejected', () async {
      final state = await newState();
      final good = jsonDecode(state.exportBackup()) as Map<String, dynamic>;
      for (final bad in <Map<String, Object?>>[
        {
          'programs': [
            {'id': 'custom_1', 'name': 'X'},
          ],
        },
        {'programs': 'x'},
        {
          'programs': [
            arms(id: 'custom_1').toJson(),
            arms(id: 'custom_1').toJson(),
          ],
        },
        {
          'trainingDays': [0, 8],
        },
        {
          'trainingDays': [1.5],
        },
      ]) {
        final json = jsonEncode({
          ...good,
          'settings': {...(good['settings'] as Map? ?? {}), ...bad},
        });
        await expectLater(
          state.restoreBackup(json),
          throwsA(isA<FormatException>()),
          reason: '$bad',
        );
      }
    });
  });

  group('coach', () {
    final monday = DateTime(2026, 10, 5, 12);

    test('reminders only on chosen weekdays', () {
      final list = planReminders(
        now: monday,
        hour: 18,
        minute: 0,
        goal: 3,
        finished: const [],
        trainingDays: [2, 4],
      );
      expect(list, isNotEmpty);
      expect(list.map((r) => r.at.weekday).toSet(), {2, 4});
    });

    test('mission is a planned rest outside training days', () {
      expect(
        todayMission(
          goal: 2,
          finished: const [],
          now: monday,
          trainingDays: [2, 4],
        ).kind,
        MissionKind.plannedRest,
      );
      expect(
        todayMission(
          goal: 2,
          finished: const [],
          now: monday,
          trainingDays: [1, 4],
        ).kind,
        MissionKind.trainToday,
      );
    });
  });
}

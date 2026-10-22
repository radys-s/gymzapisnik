import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/trainer.dart';
import 'package:gymzapisnik/coach/coach_context.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';

Workout workout(int i, DateTime start) => Workout(
  id: 'w$i',
  name: 'Trénink $i',
  startedAt: start,
  finishedAt: start.add(const Duration(minutes: 50)),
  exercises: [
    for (final id in ['bench_press', 'squat', 'pull_up'])
      WorkoutExercise(
        id: 'e$i$id',
        exerciseId: id,
        sets: [
          for (var s = 0; s < 3; s++)
            SetEntry(
              weight: id == 'pull_up' ? 0 : 60.0 + i,
              reps: 8,
              done: true,
            ),
        ],
      ),
  ],
);

void main() {
  final now = DateTime(2026, 10, 22, 18);
  Exercise ex(String id) => builtInExercises.firstWhere((e) => e.id == id);

  test('context has numbers, no notes, and fits the limit', () {
    final workouts = [
      for (var i = 0; i < 40; i++)
        workout(i, now.subtract(Duration(days: 40 - i))),
    ];
    workouts.last.exercises.first.note = 'tajná poznámka';
    workouts.last.note = 'tajná';
    workouts.last.name = 'Trénink s Petrem';
    workouts.last.exercises.add(
      WorkoutExercise(
        id: 'mine',
        exerciseId: 'custom_petr',
        sets: [SetEntry(weight: 10, reps: 12, done: true)],
      ),
    );
    Exercise any(String id) => id == 'custom_petr'
        ? const Exercise(
            id: 'custom_petr',
            name: 'Petrův zdvih',
            muscle: 'Ramena',
            custom: true,
          )
        : ex(id);
    final c = coachContext(
      now: now,
      workouts: workouts,
      exercise: any,
      adult: false,
      weekGoal: 3,
      bodyweightKg: 70,
    );
    final text = jsonEncode(c);
    expect(text.length, lessThanOrEqualTo(5500));
    expect(text, isNot(contains('tajná')));
    expect(text, isNot(contains('Petr')));
    expect(text, contains('vlastní cvik (Ramena)'));
    expect(c['adult'], false);
    expect(c.containsKey('bodyweightKg'), isFalse);
    expect(c['today'], '2026-10-22 čt');
    final recent = c['recentWorkouts'] as List;
    expect((recent.first as Map).containsKey('name'), isFalse);
    final sets = ((recent.first as Map)['exercises'] as List).first as Map;
    expect(sets['sets'], '99×8, 99×8, 99×8');
    final lifts = c['lifts'] as List;
    expect(lifts, isNotEmpty);
    expect((lifts.first as Map)['last'], hasLength(3));

    final tiny = coachContext(
      now: now,
      workouts: workouts,
      exercise: any,
      adult: true,
      weekGoal: 3,
      bodyweightKg: 70,
      maxChars: 900,
    );
    expect(jsonEncode(tiny).length, lessThanOrEqualTo(900));
    expect(tiny['bodyweightKg'], '70');
  });

  test('chat keeps last 30 messages and survives backup', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    await state.saveCoachChat([
      for (var i = 0; i < 35; i++) ChatMessage(ChatRole.user, 'otázka $i', now),
    ]);
    expect(state.coachChat, hasLength(30));
    expect(state.coachChat.first.content, 'otázka 5');
    expect(backupSettingsKeys, contains('coachChat'));
    expect(state.trainerContext(now)['weekGoal'], state.weekGoal);

    String backup(String chat) =>
        '{"format":"$backupFormat","version":1,'
        '"settings":{"coachChat":$chat},"workouts":[]}';
    final ok = decodeBackup(
      backup(
        '[{"role":"assistant","content":"Ahoj","at":"2026-10-22T10:00:00Z"}]',
      ),
    );
    expect(ok.settings['coachChat'], hasLength(1));
    expect(
      () => decodeBackup(backup('[{"role":"x","content":"y"}]')),
      throwsFormatException,
    );
  });
}

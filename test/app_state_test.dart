import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';

void main() {
  late AppDatabase db;
  late AppState state;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    state = AppState(LocalStore(db));
    await state.load();
  });

  tearDown(() => db.close());

  test('custom exercise is saved and found after reload', () async {
    final e = await state.addCustomExercise(
      name: '  Přítah na kladce  ',
      muscle: 'Záda',
      type: ExerciseType.weighted,
    );
    expect(e.name, 'Přítah na kladce');
    final again = AppState(LocalStore(db));
    await again.load();
    expect(again.exercise(e.id).name, 'Přítah na kladce');
    expect(again.allExercises.first.id, e.id);
  });

  test('empty name is rejected', () {
    expect(
      state.addCustomExercise(
        name: ' ',
        muscle: 'Záda',
        type: ExerciseType.weighted,
      ),
      throwsArgumentError,
    );
  });

  test('unknown exercise id still resolves', () {
    expect(state.exercise('gone').name, 'Neznámý cvik');
  });
}

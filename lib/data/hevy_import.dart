import 'package:uuid/uuid.dart';

import '../core/text.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';

/// Import exportu z Hevy (Profil → Nastavení → Export data → workout_data.csv).
/// Čistý Dart bez Flutteru.
///
/// Jedna řádka CSV = jedna série. Sloupce: title, start_time, end_time,
/// description, exercise_title, superset_id, exercise_notes, set_index,
/// set_type, weight_kg | weight_lbs, reps, distance_*, duration_seconds, rpe.
/// Čas je ve tvaru `15 Jul 2026, 09:52` (místní čas).
class HevyImport {
  final List<Workout> workouts;

  /// Cviky, které nejsou v katalogu (nové vlastní cviky).
  final List<Exercise> newExercises;

  /// Řádky, které se nepodařilo přečíst.
  final int skippedRows;

  const HevyImport({
    required this.workouts,
    required this.newExercises,
    required this.skippedRows,
  });
}

const _uuid = Uuid();
const _lbToKg = 0.45359237;

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

/// Hevy názvy, které se liší od našeho katalogu (po [_normalize]).
const _aliases = {
  'bench press': 'bench_press',
  'incline bench press': 'incline_press',
  'squat': 'squat',
  'romanian deadlift': 'romanian_deadlift',
  'overhead press': 'overhead_press',
  'shoulder press': 'shoulder_press',
  'lat pulldown': 'lat_pulldown',
  'seated row': 'seated_row',
  'bent over row': 'barbell_row',
  'bicep curl': 'biceps_curl',
  'triceps pushdown': 'triceps_pushdown',
  'pull up': 'pull_up',
  'chin up': 'pull_up',
  'push up': 'push_up',
  'standing calf raise': 'calf_raise',
  'lateral raise': 'lateral_raise',
  'hip thrust': 'hip_thrust',
  'deadlift': 'deadlift',
  'leg press': 'leg_press',
  'leg extension': 'leg_extension',
  'seated leg curl': 'leg_curl',
  'lying leg curl': 'leg_curl',
  'face pull': 'face_pull',
  'hammer curl': 'hammer_curl',
  'dip': 'dips',
  'triceps dip': 'dips',
};

/// Hevy názvy s vybavením, které mají jiný cvik než varianta s tyčí.
const _equipmentAliases = {
  'bench press (dumbbell)': 'dumbbell_bench_press',
  'incline bench press (dumbbell)': 'incline_dumbbell_press',
  'shoulder press (dumbbell)': 'dumbbell_shoulder_press',
  'overhead press (dumbbell)': 'dumbbell_shoulder_press',
  'bent over row (dumbbell)': 'dumbbell_row',
  'one arm row (dumbbell)': 'dumbbell_row',
  'bicep curl (barbell)': 'barbell_curl',
  'bicep curl (cable)': 'cable_curl',
  'lateral raise (cable)': 'cable_lateral_raise',
  'squat (smith machine)': 'smith_squat',
  'squat (machine)': 'hack_squat',
};

/// Název bez závorky s vybavením a diakritiky: `Bench Press (Barbell)` → `bench press`.
String _normalize(String name) {
  var text = fold(name.replaceAll(RegExp(r'\([^)]*\)'), ''));
  text = text.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Načte CSV z Hevy. Při neznámém souboru hodí [FormatException]
/// s českou zprávou.
HevyImport parseHevyCsv(String source, {Iterable<Exercise> custom = const []}) {
  final rows = _parseCsv(source.replaceFirst('﻿', ''));
  if (rows.isEmpty) {
    throw const FormatException('Soubor je prázdný.');
  }
  final header = [for (final h in rows.first) h.trim().toLowerCase()];
  int col(String name) => header.indexOf(name);
  final iTitle = col('title');
  final iStart = col('start_time');
  final iEnd = col('end_time');
  final iExercise = col('exercise_title');
  final iNote = col('exercise_notes');
  final iType = col('set_type');
  final iReps = col('reps');
  final iDesc = col('description');
  var iWeight = col('weight_kg');
  final lbs = iWeight < 0;
  if (lbs) iWeight = col('weight_lbs');
  if (iStart < 0 || iExercise < 0 || iReps < 0 || iWeight < 0) {
    throw const FormatException(
      'Soubor nevypadá jako export z Hevy (workout_data.csv).',
    );
  }

  String cell(List<String> row, int i) =>
      i >= 0 && i < row.length ? row[i].trim() : '';

  // Existující cviky podle normalizovaného názvu.
  final byName = <String, Exercise>{};
  for (final e in [...builtInExercises, ...custom]) {
    byName[_normalize(e.name)] = e;
  }
  final newExercises = <String, Exercise>{};

  Exercise resolve(String hevyName, {required bool bodyweight}) {
    final key = _normalize(hevyName);
    final equipment =
        _equipmentAliases[hevyName.trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        )];
    if (equipment != null) {
      for (final e in builtInExercises) {
        if (e.id == equipment) return e;
      }
    }
    final known = byName[key];
    if (known != null) return known;
    final aliased = _aliases[key];
    if (aliased != null) {
      for (final e in builtInExercises) {
        if (e.id == aliased) return e;
      }
    }
    return newExercises.putIfAbsent(
      key,
      () => Exercise(
        id: 'hevy_${_uuid.v5(Namespace.url.value, 'gymzapisnik/hevy-exercise/$key')}',
        name: hevyName.trim(),
        muscle: 'Ostatní',
        type: bodyweight ? ExerciseType.bodyweight : ExerciseType.weighted,
        custom: true,
      ),
    );
  }

  final workouts = <String, Workout>{};
  var skipped = 0;
  for (final row in rows.skip(1)) {
    if (row.every((c) => c.trim().isEmpty)) continue;
    final start = _parseTime(cell(row, iStart));
    final name = cell(row, iExercise);
    final reps = int.tryParse(cell(row, iReps));
    if (start == null || name.isEmpty || reps == null || reps <= 0) {
      // Kardio, plank a podobné série bez opakování se nepřenáší.
      skipped++;
      continue;
    }
    final title = cell(row, iTitle).isEmpty ? 'Trénink' : cell(row, iTitle);
    // ID z místního času ze souboru: stejný export dá stejné ID v každém pásmu.
    final id = _uuid.v5(
      Namespace.url.value,
      'gymzapisnik/hevy/${start.toIso8601String()}|$title',
    );
    final end = _parseTime(cell(row, iEnd));
    final workout = workouts.putIfAbsent(
      id,
      () => Workout(
        id: id,
        name: title,
        startedAt: start,
        finishedAt: end != null && end.isAfter(start) ? end : start,
        note: cell(row, iDesc),
      ),
    );
    var weight = double.tryParse(cell(row, iWeight).replaceAll(',', '.')) ?? 0;
    if (lbs) weight = double.parse((weight * _lbToKg).toStringAsFixed(1));
    final bodyweight = RegExp(
      r'\((bodyweight|assisted[^)]*)\)',
      caseSensitive: false,
    ).hasMatch(name);
    final exercise = resolve(name, bodyweight: bodyweight);
    WorkoutExercise? entry;
    for (final e in workout.exercises) {
      if (e.exerciseId == exercise.id) entry = e;
    }
    entry ??= WorkoutExercise(
      id: _uuid.v5(
        Namespace.url.value,
        '$id|${exercise.id}|${workout.exercises.length}',
      ),
      exerciseId: exercise.id,
      note: cell(row, iNote),
    );
    if (!workout.exercises.contains(entry)) workout.exercises.add(entry);
    entry.sets.add(
      SetEntry(
        weight: weight,
        reps: reps,
        warmup: cell(row, iType).toLowerCase() == 'warmup',
        done: true,
      ),
    );
  }
  if (workouts.isEmpty) {
    throw const FormatException('V souboru nejsou žádné použitelné série.');
  }
  return HevyImport(
    workouts: workouts.values.toList(),
    newExercises: newExercises.values.toList(),
    skippedRows: skipped,
  );
}

/// `15 Jul 2026, 09:52` nebo ISO 8601.
DateTime? _parseTime(String text) {
  if (text.isEmpty) return null;
  final m = RegExp(
    r'^(\d{1,2})\s+([A-Za-z]{3})[a-z]*\.?\s+(\d{4}),?\s+(\d{1,2}):(\d{2})',
  ).firstMatch(text);
  if (m != null) {
    final month = _months[m.group(2)!.toLowerCase()];
    if (month == null) return null;
    return DateTime(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
    );
  }
  return DateTime.tryParse(text);
}

/// Minimální CSV parser: čárka, uvozovky, `""` jako uvozovka, CRLF.
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var i = 0;
  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      endCell();
    } else if (c == '\n') {
      endRow();
    } else if (c != '\r') {
      cell.write(c);
    }
    i++;
  }
  if (cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

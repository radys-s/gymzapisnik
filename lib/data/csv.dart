import '../domain/models.dart';
import '../domain/stats.dart';

/// Export sérií do CSV pro český Excel: středník jako oddělovač,
/// desetinná čárka a BOM, aby Excel poznal UTF-8 (diakritika).
String workoutsToCsv(
  Iterable<Workout> workouts,
  Exercise Function(String exerciseId) exerciseOf,
) {
  final rows = <List<Object?>>[
    [
      'Datum',
      'Trénink',
      'Cvik',
      'Partie',
      'Série',
      'Rozcvička',
      'Váha (kg)',
      'Opakování',
      'Odhad 1RM (kg)',
      'Poznámka',
    ],
  ];
  final sorted = workouts.where((w) => w.finished).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  for (final w in sorted) {
    final local = w.date.toLocal();
    final date =
        '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
    for (final e in w.exercises) {
      final exercise = exerciseOf(e.exerciseId);
      for (var i = 0; i < e.sets.length; i++) {
        final s = e.sets[i];
        if (!s.done || s.reps <= 0) continue;
        rows.add([
          date,
          w.name,
          exercise.name,
          exercise.muscle,
          i + 1,
          s.warmup ? 'ano' : '',
          _num(s.weight),
          s.reps,
          exercise.type == ExerciseType.weighted && !s.warmup
              ? _num(e1rm(s.weight, s.reps))
              : '',
          [w.note, e.note].where((n) => n.isNotEmpty).join(' | '),
        ]);
      }
    }
  }
  return '\uFEFF${rows.map((r) => r.map(_cell).join(';')).join('\r\n')}\r\n';
}

String _two(int v) => v.toString().padLeft(2, '0');

String _num(double v) {
  final rounded = double.parse(v.toStringAsFixed(1));
  final text = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
  return text.replaceAll('.', ',');
}

String _cell(Object? value) {
  var text = '${value ?? ''}';
  // Vzorce v buňkách by Excel spustil (CSV injection).
  if (text.startsWith(RegExp(r'[=+\-@]'))) text = "'$text";
  return text.contains(RegExp('[";\r\n]'))
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

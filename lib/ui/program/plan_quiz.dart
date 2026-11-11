import '../../coach/plan_quiz.dart';

/// „3× týdně · 5 cviků · pauza 2 min“.
String planFacts(PlanRecommendation r) {
  final rest = r.restSeconds % 60 == 0
      ? '${r.restSeconds ~/ 60} min'
      : '${r.restSeconds} s';
  return '${r.perWeek}× týdně · ${r.exercises} ${_cviku(r.exercises)} · '
      'pauza $rest';
}

String _cviku(int n) => n == 1
    ? 'cvik'
    : n < 5
    ? 'cviky'
    : 'cviků';

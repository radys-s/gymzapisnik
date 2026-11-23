import '../../coach/plan_quiz.dart';
import '../../core/i18n.dart';

/// „3× týdně · 5 cviků · pauza 2 min“.
String planFacts(PlanRecommendation r) {
  final rest = r.restSeconds % 60 == 0
      ? '${r.restSeconds ~/ 60} min'
      : '${r.restSeconds} s';
  if (isEnglish) {
    return '${r.perWeek}× a week · ${r.exercises} '
        '${r.exercises == 1 ? 'exercise' : 'exercises'} · rest $rest';
  }
  return '${r.perWeek}× týdně · ${r.exercises} ${_cviku(r.exercises)} · '
      'pauza $rest';
}

String _cviku(int n) => n == 1
    ? 'cvik'
    : n < 5
    ? 'cviky'
    : 'cviků';

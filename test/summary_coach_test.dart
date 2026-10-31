import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/progression.dart';
import 'package:gymzapisnik/coach/summary_coach.dart';

String verdict({
  int number = 5,
  int records = 0,
  String? recordExercise,
  int compared = 3,
  int better = 0,
  int worse = 0,
}) => summaryVerdict(
  number: number,
  records: records,
  recordExercise: recordExercise,
  compared: compared,
  better: better,
  worse: worse,
);

Suggestion s(SuggestionKind kind, double kg, int reps) =>
    Suggestion(kind: kind, weight: kg, reps: reps, sets: 3, reason: '');

void main() {
  test('verdict picks the most important news first', () {
    expect(verdict(number: 1, records: 2), startsWith('První trénink'));
    expect(
      verdict(records: 1, recordExercise: 'Dřep'),
      'Nový rekord: Dřep. Takhle vypadá progres.',
    );
    expect(verdict(records: 3), startsWith('3 nové rekordy.'));
    expect(verdict(records: 6), startsWith('6 nových rekordů.'));
    expect(verdict(compared: 0), startsWith('Nové cviky'));
    expect(verdict(better: 2, worse: 1), contains('v 2 z 3 cviků'));
    expect(verdict(compared: 1, better: 1), contains('v 1 z 1 cviku'));
    expect(verdict(), startsWith('Stejně jako minule'));
    expect(verdict(better: 1, worse: 2), startsWith('Dnes slabší den'));
    expect(verdict(better: 1, worse: 1), startsWith('Něco líp'));
  });

  test('next target only when the coach says something concrete', () {
    expect(
      nextTargetLabel(
        'Dřep',
        s(SuggestionKind.increase, 62.5, 5),
        weighted: true,
      ),
      'Dřep 62,5 kg × 5',
    );
    expect(
      nextTargetLabel('Shyby', s(SuggestionKind.hold, 0, 8), weighted: false),
      'Shyby × 8',
    );
    // Bez historie nebo bez Pro (start, 0 kg) nic nevymýšlí.
    expect(
      nextTargetLabel('Dřep', s(SuggestionKind.start, 20, 5), weighted: true),
      isNull,
    );
    expect(
      nextTargetLabel('Dřep', s(SuggestionKind.hold, 0, 5), weighted: true),
      isNull,
    );
  });
}

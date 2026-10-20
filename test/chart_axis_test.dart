import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/widgets/chart_axis.dart';

List<int> shown(int count) => [
  for (var i = 0; i < count; i++)
    if (showDateLabel(i, count)) i,
];

void main() {
  test('date labels: first and last, none crowding the last', () {
    expect(shown(1), [0]);
    expect(shown(2), [0, 1]);
    expect(shown(5), [0, 2, 4]);
    // Bod 6 by se lepil na poslední 7.
    expect(shown(8), [0, 2, 4, 7]);
    expect(showDateLabel(-1, 3), isFalse);
    expect(showDateLabel(3, 3), isFalse);
  });
}

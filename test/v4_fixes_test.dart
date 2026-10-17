import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/plates.dart';
import 'package:gymzapisnik/domain/models.dart';

void main() {
  test('plates only for barbell and custom exercises', () {
    expect(usesPlates('bench_press', custom: false), isTrue);
    expect(usesPlates('squat', custom: false), isTrue);
    expect(usesPlates('lateral_raise', custom: false), isFalse);
    expect(usesPlates('my_press', custom: true), isTrue);
  });

  test('workout without a valid start is rejected, not dated 1970', () {
    expect(
      () => Workout.fromJson({'id': 'x', 'name': 'x'}),
      throwsFormatException,
    );
    expect(
      () => Workout.fromJson({'id': 'x', 'name': 'x', 'startedAt': 'nope'}),
      throwsFormatException,
    );
  });
}

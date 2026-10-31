import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/core/format.dart';

void main() {
  test('calendar days ignore clock time and DST shift', () {
    // Přechod na zimní čas (25. 10. 2026): den má 25 hodin.
    final before = DateTime(2026, 10, 24, 23, 30);
    final after = DateTime(2026, 10, 25, 23, 30);
    expect(calendarDaysBetween(before, after), 1);
    expect(
      calendarDaysBetween(
        DateTime(2026, 3, 28, 0, 30),
        DateTime(2026, 3, 29, 23, 59),
      ),
      1,
    );
    expect(
      calendarDaysBetween(
        DateTime(2026, 10, 10, 23, 59),
        DateTime(2026, 10, 11, 0, 1),
      ),
      1,
    );
  });

  test('relative day labels', () {
    final now = DateTime(2026, 10, 10, 8); // sobota
    expect(relativeDay(DateTime(2026, 10, 10, 6), now), 'Dnes');
    expect(relativeDay(DateTime(2026, 10, 9, 23), now), 'Včera');
    expect(relativeDay(DateTime(2026, 10, 6, 18), now), 'Úterý');
    expect(relativeDay(DateTime(2026, 10, 3, 18), now), '3. 10. 2026');
  });

  test('volume groups thousands with a non-breaking space', () {
    expect(formatVolume(950.4), '950');
    expect(formatVolume(8732), '8 732');
    expect(formatVolume(1234567.6), '1 234 568');
  });
}

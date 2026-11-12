import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/widgets/muscle_tile_grid.dart';

void main() {
  testWidgets('selecting tiles never moves or resizes any tile', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final selected = <String>{};
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (_, set) => MuscleTileGrid(
                selected: selected,
                onToggle: (id) => set(
                  () => selected.contains(id)
                      ? selected.remove(id)
                      : selected.add(id),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    Map<String, Rect> rects() => {
      for (final f in dayFocuses)
        f.id: t.getRect(find.byKey(ValueKey('muscle-${f.id}'))),
    };
    final before = rects();
    // Tři sloupce stejné šířky.
    expect(before.values.map((r) => r.width).toSet().length, 1);
    for (final id in ['chest', 'biceps', 'legs']) {
      await t.tap(find.byKey(ValueKey('muscle-$id')));
      await t.pumpAndSettle();
    }
    expect(selected, {'chest', 'biceps', 'legs'});
    expect(rects(), before);
    // Odznačení taky nic nepohne.
    await t.tap(find.byKey(const ValueKey('muscle-chest')));
    await t.pumpAndSettle();
    expect(selected, {'biceps', 'legs'});
    expect(rects(), before);
  });
}

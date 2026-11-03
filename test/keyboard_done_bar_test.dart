import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/widgets/keyboard_done_bar.dart';

void main() {
  testWidgets('iOS keyboard gets a Hotovo bar that closes it', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(tester.view.resetViewInsets);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        builder: (_, child) => KeyboardDoneBar(child: child!),
        home: Scaffold(
          body: TextField(focusNode: focus, keyboardType: TextInputType.number),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // Klávesnice vyjede až po fokusu: pole ho musí udržet.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.text('Hotovo'));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}

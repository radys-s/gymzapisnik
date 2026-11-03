import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/movement.dart';
import 'package:gymzapisnik/ui/widgets/exercise_media.dart';

const _colors = FigureColors(
  Color(0xFFE4E4E7),
  Color(0xFF6E6E76),
  Color(0x889A9AA2),
  Color(0xFF76B900),
  Color(0xFF26262A),
);

void main() {
  test('every built-in exercise has a movement pattern', () {
    for (final e in builtInExercises) {
      expect(movements.containsKey(e.pattern), isTrue, reason: e.id);
    }
  });

  test('figures paint at start, middle and end without errors', () {
    for (final e in builtInExercises) {
      for (final t in const [0.0, 0.5, 1.0]) {
        final recorder = ui.PictureRecorder();
        FigurePainter(
          movementFor(e.pattern),
          e.equipment,
          t,
          _colors,
        ).paint(Canvas(recorder), const Size(120, 80));
        recorder.endRecording().dispose();
      }
    }
  });

  // Kontaktní arch všech figurek pro vizuální kontrolu:
  // FIGURE_SHEET=cesta.png flutter test test/figure_test.dart
  final sheet = Platform.environment['FIGURE_SHEET'];
  test('contact sheet', skip: sheet == null, () async {
    const cell = 150.0, cols = 10;
    final list = builtInExercises;
    final rows = (list.length / cols).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, cell * cols, 1e5),
      Paint()..color = Colors.black,
    );
    for (final (i, e) in list.indexed) {
      final dx = (i % cols) * cell, dy = (i ~/ cols) * cell;
      canvas.save();
      canvas.translate(dx, dy);
      final t = double.parse(Platform.environment['FIGURE_T'] ?? '1');
      FigurePainter(
        movementFor(e.pattern),
        e.equipment,
        t,
        _colors,
      ).paint(canvas, const Size(cell, cell - 22));
      final tp = TextPainter(
        text: TextSpan(
          text: e.id,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cell);
      tp.paint(canvas, Offset(4, cell - 18));
      canvas.restore();
    }
    final image = await recorder.endRecording().toImage(
      (cell * cols).toInt(),
      (cell * rows).toInt(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(sheet!).writeAsBytesSync(png!.buffer.asUint8List());
  });
}

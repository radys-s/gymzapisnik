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
  Color(0xFF9A9AA2),
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

  // Contact sheet of all figures for visual review:
  // FIGURE_SHEET=figures.png flutter test test/figure_test.dart
  final sheet = Platform.environment['FIGURE_SHEET'];
  test('contact sheet', skip: sheet == null, () async {
    final cell = double.parse(Platform.environment['FIGURE_CELL'] ?? '150');
    final cols = int.parse(Platform.environment['FIGURE_COLS'] ?? '10');
    // FIGURE_IDS=squat,bench_press limits the sheet to those exercises.
    final ids = Platform.environment['FIGURE_IDS']?.split(',');
    final list = ids == null
        ? builtInExercises
        : [
            for (final e in builtInExercises)
              if (ids.contains(e.id)) e,
          ];
    final rows = (list.length / cols).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cell * cols, 1e5),
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
        work: bodyPartsOf(e.id).work,
        help: bodyPartsOf(e.id).help,
        ghost: true,
        path: true,
        effort: double.parse(Platform.environment['FIGURE_EFFORT'] ?? '1'),
      ).paint(canvas, Size(cell, cell - 22));
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

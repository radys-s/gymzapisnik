import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

/// Zda ukázat datum pod bodem [i] z [count]: první, poslední a zhruba
/// čtyři mezi nimi. Popisek těsně před posledním se vynechá, jinak by se
/// s ním překrýval.
bool showDateLabel(int i, int count) {
  if (i < 0 || i >= count) return false;
  final last = count - 1;
  if (i == last) return true;
  final step = (count / 4).ceil();
  return i % step == 0 && last - i >= step;
}

/// Popisek osy, který nepřeteče přes okraj grafu.
Widget axisLabel(TitleMeta meta, String text, TextStyle style) =>
    SideTitleWidget(
      meta: meta,
      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
      child: Text(text, style: style, maxLines: 1),
    );

/// Popisek svislé osy bez krajních hodnot, které fl_chart přidá mimo
/// mřížku a které se tlačí na sousední čáru („74" hned pod „80").
/// Kraj, který na mřížku padne přesně, zůstává.
Widget valueAxisLabel(
  double value,
  TitleMeta meta,
  String text,
  TextStyle style,
) => _offGridEdge(value, meta)
    ? const SizedBox.shrink()
    : axisLabel(meta, text, style);

bool _offGridEdge(double value, TitleMeta meta) {
  const eps = 1e-6;
  final edge = (value - meta.min).abs() < eps || (value - meta.max).abs() < eps;
  if (!edge) return false;
  final steps = value / meta.appliedInterval;
  return (steps - steps.round()).abs() > eps;
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tlačítko podle popisku pro čtečku (tam, kde nemá tooltip).
Finder byLabel(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

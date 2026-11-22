import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../design/tokens.dart';

/// Odznak série: R = rozcvička, D = drop, S = do selhání, jinak pořadí.
String setBadge(SetEntry set, int index) => set.warmup
    ? 'R'
    : set.kind == SetKind.normal
    ? '$index'
    : set.kind.badge;

/// Jméno série pro čtečku obrazovky.
String setName(SetEntry set, String label) => set.warmup
    ? 'Rozcvička'
    : set.kind == SetKind.normal
    ? 'Série $label'
    : set.kind.label;

/// Volby typu série do menu u odznaku. Hodnota je `working`, `warmup`
/// nebo název [SetKind].
List<PopupMenuEntry<String>> setTypeItems(SetEntry set) => [
  CheckedPopupMenuItem(
    value: 'working',
    checked: !set.warmup && set.kind == SetKind.normal,
    child: const Text('Pracovní série'),
  ),
  CheckedPopupMenuItem(
    value: 'warmup',
    checked: set.warmup,
    child: const Text('Rozcvička'),
  ),
  for (final k in [SetKind.drop, SetKind.failure])
    CheckedPopupMenuItem(
      value: k.name,
      checked: !set.warmup && set.kind == k,
      child: Text(k.label),
    ),
];

/// Barva odznaku: rozcvička zlatá, drop fialová, selhání červená,
/// pracovní série bílá (jako v Hevy).
Color setKindColor(SetEntry set, AppPalette p) => set.warmup
    ? AppPalette.amber
    : switch (set.kind) {
        SetKind.drop => AppPalette.violet,
        SetKind.failure => p.negative,
        SetKind.normal => p.label,
      };

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../domain/models.dart';
import '../design/tokens.dart';

/// Odznak série: R = rozcvička, D = drop, S = do selhání, jinak pořadí.
String setBadge(SetEntry set, int index) => set.warmup
    ? tr('R', 'W')
    : set.kind == SetKind.normal
    ? '$index'
    : set.kind.badge;

/// Jméno série pro čtečku obrazovky.
String setName(SetEntry set, String label) => set.warmup
    ? tr('Rozcvička', 'Warm-up')
    : set.kind == SetKind.normal
    ? tr('Série $label', 'Set $label')
    : set.kind.label;

/// Volby typu série do menu u odznaku. Hodnota je `working`, `warmup`
/// nebo název [SetKind].
List<PopupMenuEntry<String>> setTypeItems(SetEntry set) => [
  CheckedPopupMenuItem(
    value: 'working',
    checked: !set.warmup && set.kind == SetKind.normal,
    child: Text(tr('Pracovní série', 'Working set')),
  ),
  CheckedPopupMenuItem(
    value: 'warmup',
    checked: set.warmup,
    child: Text(tr('Rozcvička', 'Warm-up')),
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

import 'package:flutter/material.dart';

import '../../domain/models.dart';

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

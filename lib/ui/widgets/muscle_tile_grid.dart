import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../home/body_map.dart';

/// Výběr partií jako mřížka 3 × 3 stejně velkých dlaždic s výřezem
/// postavy. Výběr mění jen barvy uvnitř dlaždice, nikdy její velikost,
/// takže se nic nepřeskládá.
class MuscleTileGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Volitelný druhý řádek dlaždice (např. „3 cviky“).
  final String? Function(String focusId)? caption;

  static const tileHeight = 108.0;

  const MuscleTileGrid({
    super.key,
    required this.selected,
    required this.onToggle,
    this.caption,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = Space.s;
      final w = ((box.maxWidth - gap * 2) / 3).floorToDouble();
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final f in dayFocuses)
            SizedBox(
              width: w,
              height: tileHeight,
              child: _Tile(
                key: ValueKey('muscle-${f.id}'),
                id: f.id,
                name: f.name,
                caption: caption?.call(f.id),
                selected: selected.contains(f.id),
                onTap: () => onToggle(f.id),
              ),
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  final String id;
  final String name;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;
  const _Tile({
    super.key,
    required this.id,
    required this.name,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(p.controlRadius + 4);
    return Semantics(
      button: true,
      selected: selected,
      label: [name, ?caption].join(', '),
      excludeSemantics: true,
      child: PopSelect(
        selected: selected,
        child: PressScale(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1 : 0),
            duration: Motion.of(context, Motion.quick),
            curve: Motion.curve,
            builder: (context, t, _) => Material(
              color: Color.lerp(p.grouped, p.accent.withValues(alpha: 0.14), t),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: Color.lerp(p.separator, p.accent, t)!,
                  width: 1 + t,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: MuscleSilhouette(focusId: id, lit: t),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              color: Color.lerp(p.label, p.accent, t),
                            ),
                          ),
                          if (caption case final c?)
                            Text(
                              c,
                              maxLines: 1,
                              style: text.labelSmall?.copyWith(
                                color: p.secondaryLabel,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Fajfka v rohu: pevné místo, jen se rozsvítí.
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * t,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: p.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: p.onCta,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

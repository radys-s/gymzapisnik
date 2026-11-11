import 'package:flutter/material.dart';

import '../../coach/routine_audit.dart' show weeklyRange;
import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Partie tento týden: odcvičené série proti doporučenému rozsahu.
class CoverageCard extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const CoverageCard({super.key, required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final sets = state.coverageOn(now);
    String n(double v) => v % 1 == 0
        ? v.toInt().toString()
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partie tento týden', style: text.titleMedium),
          Text(
            'Přímé série; vedlejší cvik se počítá napůl.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.m),
          for (final f in dayFocuses)
            if (weeklyRange(f.id) case (final low, final high))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s),
                child: Semantics(
                  label:
                      '${f.name}: ${n(sets[f.id] ?? 0)} sérií z doporučených $low až $high',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          f.name,
                          style: text.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((sets[f.id] ?? 0) / low)
                                .clamp(0, 1)
                                .toDouble(),
                            minHeight: 8,
                            backgroundColor: p.fill,
                            color: (sets[f.id] ?? 0) > high
                                ? p.gold
                                : (sets[f.id] ?? 0) >= low
                                ? p.positive
                                : p.accent,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${n(sets[f.id] ?? 0)}/$low',
                          textAlign: TextAlign.end,
                          style: text.bodySmall?.copyWith(
                            color: p.secondaryLabel,
                            fontFeatures: tabular,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

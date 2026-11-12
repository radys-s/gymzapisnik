import 'package:flutter/material.dart';

import '../../coach/routine_audit.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';

/// Živá kontrola rutiny v editoru: co chybí a co je navíc. Každý nález
/// s návrhem cviku má „Přidat“, které cvik vloží do správného dne.
class AuditPanel extends StatelessWidget {
  final AppState state;
  final List<AuditFinding> findings;
  final void Function(AuditFinding finding) onAdd;

  const AuditPanel({
    super.key,
    required this.state,
    required this.findings,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final gaps = findings.where((f) => f.isGap).length;
    return AnimatedSize(
      duration: Motion.of(context, Motion.quick),
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: Panel(
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      gaps == 0 ? Icons.verified_rounded : Icons.rule_rounded,
                      color: gaps == 0 ? p.positive : p.accent,
                      size: 20,
                    ),
                    const SizedBox(width: Space.s),
                    Expanded(
                      child: Text(
                        findings.isEmpty
                            ? 'Kontrola: rutina pokrývá všechno'
                            : gaps == 0
                            ? 'Kontrola: bez mezer'
                            : 'Kontrola: $gaps '
                                  '${gaps == 1 ? 'mezera' : (gaps < 5 ? 'mezery' : 'mezer')}',
                        style: text.titleSmall,
                      ),
                    ),
                  ],
                ),
                for (final (i, f) in findings.take(6).indexed)
                  Reveal(
                    key: ValueKey(f.id),
                    index: i,
                    child: _FindingRow(
                      finding: f,
                      exerciseName: f.exerciseId == null
                          ? null
                          : state.exercise(f.exerciseId!).name,
                      onAdd: f.exerciseId == null ? null : () => onAdd(f),
                    ),
                  ),
                if (findings.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.s),
                    child: Text(
                      'A další ${findings.length - 6}.',
                      style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  final AuditFinding finding;
  final String? exerciseName;
  final VoidCallback? onAdd;
  const _FindingRow({
    required this.finding,
    required this.exerciseName,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Space.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              color: finding.isGap ? p.accent : p.tertiaryLabel,
            ),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(finding.title, style: text.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  exerciseName == null
                      ? finding.detail
                      : '${finding.detail} Návrh: $exerciseName.',
                  style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
          if (onAdd != null)
            TextButton(
              onPressed: onAdd,
              child: Semantics(
                label: 'Přidat $exerciseName',
                excludeSemantics: true,
                child: const Text('Přidat'),
              ),
            ),
        ],
      ),
    );
  }
}

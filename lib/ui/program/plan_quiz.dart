import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Otázky dotazníku „Tvůj plán“: cíl, dny v týdnu, zkušenost a čas.
/// Stejný formulář je v úvodu aplikace i v Programu.
class PlanQuizForm extends StatelessWidget {
  final PlanAnswers answers;
  final ValueChanged<PlanAnswers> onChanged;
  const PlanQuizForm({
    super.key,
    required this.answers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget check(bool on) => on
        ? Icon(Icons.check_rounded, color: p.accent)
        : const SizedBox(width: 24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(
          header: 'Co chceš hlavně',
          children: [
            for (final g in PlanGoal.values)
              GroupedRow(
                title: g.label,
                subtitle: g.hint,
                trailing: check(g == answers.goal),
                onTap: () => onChanged(answers.copyWith(goal: g)),
              ),
          ],
        ),
        GroupedSection(
          header: 'Kolikrát týdně můžeš cvičit',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: SegmentedButton<int>(
                segments: [
                  for (var d = 2; d <= 6; d++)
                    ButtonSegment(value: d, label: Text('$d×')),
                ],
                selected: {answers.days},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    onChanged(answers.copyWith(days: s.single)),
              ),
            ),
          ],
        ),
        GroupedSection(
          header: 'Zkušenost',
          children: [
            for (final l in PlanLevel.values)
              GroupedRow(
                title: l.label,
                subtitle: l.hint,
                trailing: check(l == answers.level),
                onTap: () => onChanged(answers.copyWith(level: l)),
              ),
          ],
        ),
        GroupedSection(
          header: 'Kolik minut máš na trénink',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: SegmentedButton<int>(
                segments: [
                  for (final m in planMinutes)
                    ButtonSegment(value: m, label: Text('$m')),
                ],
                selected: {answers.minutes},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    onChanged(answers.copyWith(minutes: s.single)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shrnutí doporučení: program, proč právě on a kolik cviků.
class PlanPreview extends StatelessWidget {
  final PlanRecommendation recommendation;
  const PlanPreview(this.recommendation, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = recommendation;
    final split = findSplit(r.splitId);
    return HeroCard(
      vivid: true,
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doporučeno pro tebe',
              style: text.labelMedium?.copyWith(
                color: context.palette.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(split?.name ?? r.splitId, style: text.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(
              planFacts(r),
              style: text.bodyMedium?.copyWith(fontFeatures: tabular),
            ),
            const SizedBox(height: Space.s),
            Text(
              r.why,
              style: text.bodyMedium?.copyWith(
                color: context.palette.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// „3× týdně · 5 cviků · pauza 2 min“.
String planFacts(PlanRecommendation r) {
  final rest = r.restSeconds % 60 == 0
      ? '${r.restSeconds ~/ 60} min'
      : '${r.restSeconds} s';
  return '${r.perWeek}× týdně · ${r.exercises} ${_cviku(r.exercises)} · '
      'pauza $rest';
}

String _cviku(int n) => n == 1
    ? 'cvik'
    : n < 5
    ? 'cviky'
    : 'cviků';

/// Samostatná obrazovka dotazníku (z Programu nebo z hlavní karty).
class PlanQuizPage extends StatefulWidget {
  final AppState state;
  const PlanQuizPage(this.state, {super.key});

  @override
  State<PlanQuizPage> createState() => _PlanQuizPageState();
}

class _PlanQuizPageState extends State<PlanQuizPage> {
  late PlanAnswers answers = widget.state.planAnswers ?? const PlanAnswers();
  bool saving = false;

  Future<void> _apply() async {
    setState(() => saving = true);
    try {
      final r = await widget.state.applyPlan(answers);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Program ${findSplit(r.splitId)?.name ?? ''} je nastavený.',
            ),
          ),
        );
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => LargeTitlePage(
    title: 'Tvůj plán',
    children: [
      PlanQuizForm(
        answers: answers,
        onChanged: (a) => setState(() => answers = a),
      ),
      const SizedBox(height: Space.l),
      PlanPreview(recommendPlan(answers)),
      const SizedBox(height: Space.l),
      PrimaryButton('Použít plán', busy: saving, onPressed: _apply),
      const SizedBox(height: Space.xxl),
    ],
  );
}

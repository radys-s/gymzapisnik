import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import 'program_detail_page.dart';
import 'plan_quiz.dart';
import 'program_editor_page.dart';
import 'program_widgets.dart';

/// Program: co se cvičí který den a jak často. Vlastní programy,
/// hotové programy a frekvence na jednom místě.
class ProgramPage extends StatelessWidget {
  final AppState state;
  const ProgramPage(this.state, {super.key});

  void _open(BuildContext context, SplitTemplate program) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProgramDetailPage(state, program.id)),
  );

  // Editor přes celou obrazovku, bez lišty záložek.
  Future<void> _create(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProgramEditorPage(state),
        ),
      );

  Future<void> _free(BuildContext context) async {
    try {
      await state.setSplit(null);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Změnu se nepodařilo uložit. Zkus to znovu.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final p = context.palette;
      final current = state.split;
      final mine = state.customPrograms;
      final answers = state.planAnswers;
      final rec = recommendPlan(answers ?? const PlanAnswers());
      final recSplit = findSplit(rec.splitId);
      Widget check(SplitTemplate t) => t.id == current?.id
          ? Icon(Icons.check_rounded, color: p.accent)
          : const SizedBox.shrink();
      return LargeTitlePage(
        title: 'Program',
        children: [
          _CurrentCard(
            state: state,
            program: current,
            onOpen: current == null ? null : () => _open(context, current),
            onCreate: () => _create(context),
          ),
          const SectionHeader('Doporučeno pro tebe'),
          GroupedSection(
            footer: answers == null
                ? 'Odpověz na čtyři otázky a doporučení sedne přesně tobě.'
                : rec.why,
            children: [
              if (recSplit != null)
                GroupedRow(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: p.accent,
                  title: recSplit.name,
                  subtitle: planFacts(rec),
                  trailing: check(recSplit),
                  chevron: true,
                  onTap: () => _open(context, recSplit),
                ),
              GroupedRow(
                leading: Icon(Icons.tune_rounded, color: p.accent),
                title: answers == null ? 'Vyplnit dotazník' : 'Změnit plán',
                chevron: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlanQuizPage(state)),
                ),
              ),
            ],
          ),
          const SectionHeader('Frekvence'),
          FrequencyPanel(state),
          const SectionHeader('Moje programy'),
          GroupedSection(
            footer: mine.isEmpty
                ? 'Slož si vlastní dny, třeba ramena a triceps dohromady.'
                : null,
            children: [
              for (final t in mine)
                GroupedRow(
                  title: t.name,
                  subtitle: programSummary(t),
                  trailing: check(t),
                  chevron: true,
                  onTap: () => _open(context, t),
                ),
              GroupedRow(
                leading: Icon(Icons.add_rounded, color: p.accent),
                title: 'Vytvořit vlastní program',
                chevron: false,
                onTap: () => _create(context),
              ),
            ],
          ),
          const SectionHeader('Hotové programy'),
          GroupedSection(
            footer:
                'Hotový program jde upravit: vznikne z něj tvůj vlastní a '
                'originál zůstane.',
            children: [
              for (final t in splitTemplates)
                GroupedRow(
                  title: t.name,
                  subtitle:
                      '${perWeekLabel(t.perWeek)} · '
                      '${t.days.map((d) => d.name).join(' · ')}',
                  trailing: check(t),
                  chevron: true,
                  onTap: () => _open(context, t),
                ),
            ],
          ),
          GroupedSection(
            footer: 'Cviky si skládáš až při tréninku, bez dnů na řadě.',
            children: [
              GroupedRow(
                title: 'Volné tréninky',
                trailing: current == null
                    ? Icon(Icons.check_rounded, color: p.accent)
                    : null,
                chevron: false,
                onTap: () => _free(context),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Aktuální program: název, dny a cesta k detailu.
class _CurrentCard extends StatelessWidget {
  final AppState state;
  final SplitTemplate? program;
  final VoidCallback? onOpen;
  final VoidCallback onCreate;
  const _CurrentCard({
    required this.state,
    required this.program,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) =>
      HeroCard(vivid: true, child: Builder(builder: _content));

  Widget _content(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final program = this.program;
    final next = state.nextSplitDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktuální program',
          style: text.labelMedium?.copyWith(
            color: p.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(program?.name ?? 'Volné tréninky', style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(
          program == null
              ? 'Žádné dny na řadě. Vyber hotový program, nebo si slož '
                    'vlastní.'
              : '${programSummary(program)} · ${perWeekLabel(state.weekGoal)}',
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
        if (program != null) ...[
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (var i = 0; i < program.days.length; i++)
                Pill(
                  i == next % program.days.length
                      ? 'Na řadě: ${program.days[i].name}'
                      : program.days[i].name,
                  color: i == next % program.days.length
                      ? p.accent
                      : p.secondaryLabel,
                ),
            ],
          ),
          const SizedBox(height: Space.l),
          SecondaryButton('Zobrazit dny a cviky', onPressed: onOpen),
        ] else ...[
          const SizedBox(height: Space.l),
          PrimaryButton(
            'Vytvořit vlastní program',
            icon: Icons.add_rounded,
            onPressed: onCreate,
          ),
        ],
      ],
    );
  }
}

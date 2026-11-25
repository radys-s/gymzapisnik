import 'package:flutter/material.dart';

import '../../core/i18n.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import 'program_detail_page.dart';
import '../onboarding/onboarding_page.dart' show PlanSetupPage;
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
        showToast(
          context,
          tr(
            'Změnu se nepodařilo uložit. Zkus to znovu.',
            'Could not save the change. Try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
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
        title: tr('Program', 'Program'),
        children: [
          _CurrentCard(
            state: state,
            program: current,
            onOpen: current == null ? null : () => _open(context, current),
            onCreate: () => _create(context),
          ),
          SectionHeader(tr('Doporučeno pro tebe', 'Recommended for you')),
          GroupedSection(
            footer: answers == null
                ? tr(
                    'Odpověz na čtyři otázky a doporučení sedne přesně tobě.',
                    'Answer four questions and the recommendation will fit you exactly.',
                  )
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
                title: answers == null
                    ? tr('Vyplnit dotazník', 'Fill in the quiz')
                    : tr('Změnit plán', 'Change plan'),
                chevron: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlanSetupPage(state)),
                ),
              ),
            ],
          ),
          SectionHeader(tr('Frekvence', 'Frequency')),
          FrequencyPanel(state),
          SectionHeader(tr('Moje programy', 'My programs')),
          GroupedSection(
            footer: mine.isEmpty
                ? tr(
                    'Slož si vlastní dny, třeba ramena a triceps dohromady.',
                    'Build your own days, e.g. shoulders and triceps together.',
                  )
                : null,
            children: [
              for (final t in mine)
                GroupedRow(
                  title: t.name,
                  subtitle: programSummaryLabel(t),
                  trailing: check(t),
                  chevron: true,
                  onTap: () => _open(context, t),
                ),
              GroupedRow(
                leading: Icon(Icons.add_rounded, color: p.accent),
                title: tr('Vytvořit vlastní program', 'Create custom program'),
                chevron: false,
                onTap: () => _create(context),
              ),
            ],
          ),
          SectionHeader(tr('Hotové programy', 'Ready-made programs')),
          GroupedSection(
            footer: tr(
              'Hotový program jde upravit: vznikne z něj tvůj vlastní a '
                  'originál zůstane.',
              'You can edit a ready-made program: it becomes your own copy '
                  'and the original stays.',
            ),
            children: [
              for (final t in [...styleTemplates, ...splitTemplates])
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
            footer: tr(
              'Cviky si skládáš až při tréninku, bez dnů na řadě.',
              'You pick exercises during the workout, no days in a queue.',
            ),
            children: [
              GroupedRow(
                title: tr('Volné tréninky', 'Free workouts'),
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
          tr('Aktuální program', 'Current program'),
          style: text.labelMedium?.copyWith(
            color: p.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          program?.name ?? tr('Volné tréninky', 'Free workouts'),
          style: text.headlineSmall,
        ),
        const SizedBox(height: 2),
        Text(
          program == null
              ? tr(
                  'Žádné dny na řadě. Vyber hotový program, nebo si slož '
                      'vlastní.',
                  'No days in a queue. Pick a ready-made program, or build '
                      'your own.',
                )
              : '${programSummaryLabel(program)} · ${perWeekLabel(state.weekGoal)}',
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
                      ? tr(
                          'Na řadě: ${program.days[i].name}',
                          'Next: ${program.days[i].name}',
                        )
                      : program.days[i].name,
                  color: i == next % program.days.length
                      ? p.accent
                      : p.secondaryLabel,
                ),
            ],
          ),
          const SizedBox(height: Space.l),
          SecondaryButton(
            tr('Zobrazit dny a cviky', 'Show days and exercises'),
            onPressed: onOpen,
          ),
        ] else ...[
          const SizedBox(height: Space.l),
          PrimaryButton(
            tr('Vytvořit vlastní program', 'Create custom program'),
            icon: Icons.add_rounded,
            onPressed: onCreate,
          ),
        ],
      ],
    );
  }
}

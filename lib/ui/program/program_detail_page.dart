import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import 'program_editor_page.dart';
import 'program_widgets.dart';

/// Náhled programu: dny a cviky, použití, úprava, smazání.
class ProgramDetailPage extends StatefulWidget {
  final AppState state;
  final String programId;
  const ProgramDetailPage(this.state, this.programId, {super.key});

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  AppState get state => widget.state;
  bool _busy = false;

  Future<void> _guard(Future<void> Function() action, String error) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showToast(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _use(SplitTemplate program) => _guard(() async {
    await state.setSplit(program.id);
    if (mounted) showToast(context, 'Program ${program.name} je aktivní.');
  }, 'Program se nepodařilo zvolit. Zkus to znovu.');

  bool _editing = false;

  Future<void> _edit(SplitTemplate program) async {
    // Dvojí klepnutí by otevřelo dva editory a uložilo dvě kopie.
    if (_editing) return;
    _editing = true;
    final String? id;
    try {
      // Editor přes celou obrazovku, bez lišty záložek.
      id = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProgramEditorPage(state, initial: program),
        ),
      );
    } finally {
      _editing = false;
    }
    // Z hotového programu vznikla kopie: ukaž rovnou ji.
    final copy = id;
    if (copy == null || copy == program.id || !mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProgramDetailPage(state, copy)),
    );
  }

  Future<void> _delete(SplitTemplate program) async {
    final ok = await confirmAction(
      context,
      title: 'Smazat program?',
      message:
          'Program ${program.name} zmizí. Odcvičené tréninky zůstanou '
          'v historii.',
      confirm: 'Smazat',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _guard(() async {
      await state.deleteProgram(program.id);
      if (mounted) Navigator.pop(context);
    }, 'Program se nepodařilo smazat. Zkus to znovu.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final raw = findSplit(widget.programId, state.customPrograms);
      if (raw == null) return const Scaffold();
      // Stejné dny a cviky, jaké se pak opravdu cvičí.
      final program = state.fitted(raw);
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final active = state.split?.id == program.id;
      return LargeTitlePage(
        title: program.name,
        bottom: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              Space.s,
              Space.page,
              Space.s,
            ),
            child: active
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: p.accent),
                      const SizedBox(width: Space.s),
                      Flexible(
                        child: Text(
                          'Tento program používáš',
                          style: text.titleSmall,
                        ),
                      ),
                    ],
                  )
                : PrimaryButton(
                    'Používat tento program',
                    busy: _busy,
                    onPressed: () => _use(program),
                  ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.l),
            child: Text(
              program.custom
                  ? '${programSummary(program)} · vlastní program'
                  : '${program.description} '
                        'Doporučeno ${perWeekLabel(program.perWeek)}.',
              style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            ),
          ),
          for (var i = 0; i < program.days.length; i++)
            ProgramDayPanel(state: state, index: i, day: program.days[i]),
          const SizedBox(height: Space.s),
          SecondaryButton(
            program.custom ? 'Upravit program' : 'Upravit jako vlastní',
            icon: Icons.edit_outlined,
            onPressed: _busy ? null : () => _edit(raw),
          ),
          if (program.custom) ...[
            const SizedBox(height: Space.s),
            SecondaryButton(
              'Smazat program',
              destructive: true,
              onPressed: _busy ? null : () => _delete(program),
            ),
          ],
        ],
      );
    },
  );
}

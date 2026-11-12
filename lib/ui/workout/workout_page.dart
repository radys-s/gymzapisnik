import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../coach/plates.dart';
import '../../coach/progression.dart';
import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/last_delta.dart';
import '../../domain/models.dart';
import '../../domain/set_match.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/haptics.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../exercises/exercise_detail_page.dart';
import '../widgets/labels.dart';
import '../widgets/set_kind.dart';
import '../widgets/exercise_media.dart';
import 'alternatives_page.dart';
import 'exercise_picker.dart';
import 'plates_sheet.dart';
import 'set_sheet.dart';

part 'workout_page/timers.dart';
part 'workout_page/exercise_card.dart';
part 'workout_page/set_row.dart';
part 'workout_page/reorder_sheet.dart';

/// Rozepsaný trénink. Každá změna se hned ukládá (přežije zavření aplikace).
class WorkoutPage extends StatefulWidget {
  final AppState state;
  const WorkoutPage(this.state, {super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  AppState get state => widget.state;
  bool _busy = false;

  void _snack(String text) {
    if (mounted) showToast(context, text);
  }

  /// Pauza jen pro tenhle cvik (těžký dřep chce víc než bicepsový zdvih).
  Future<void> _pickRest(String exerciseId) async {
    final own = state.profile.restFor(exerciseId);
    final base = state.profile.restSeconds;
    // 0 = výchozí z nastavení.
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.l,
          ),
          child: GroupedSection(
            header: 'Pauza u cviku ${state.exercise(exerciseId).name}',
            footer: 'Platí pro tento cvik i v dalších trénincích.',
            children: [
              for (final s in [0, 60, 90, 120, 150, 180, 240])
                GroupedRow(
                  title: s == 0 ? 'Výchozí (${restLabel(base)})' : restLabel(s),
                  trailing: (s == 0 ? own == null : own == s)
                      ? Icon(Icons.check_rounded, color: sheet.palette.accent)
                      : null,
                  onTap: () => Navigator.pop(sheet, s),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    try {
      await state.setExerciseRest(exerciseId, picked == 0 ? null : picked);
    } catch (_) {
      _snack('Pauzu se nepodařilo uložit. Zkus to znovu.');
    }
  }

  Future<List<String>?> _pickExercises({bool multiple = true}) =>
      Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => ExercisePickerPage(state, multiple: multiple),
        ),
      );

  bool _picking = false;

  Future<void> _addExercises() async {
    // Dvojí klepnutí by otevřelo dva výběry nad sebou.
    if (_picking) return;
    _picking = true;
    final List<String>? ids;
    try {
      ids = await _pickExercises();
    } finally {
      _picking = false;
    }
    if (ids == null) return;
    var failed = 0;
    for (final id in ids) {
      try {
        await state.addExercise(id);
      } catch (_) {
        failed++;
      }
    }
    if (failed > 0) {
      _snack(
        failed == ids.length
            ? 'Cvik se nepodařilo přidat. Zkus to znovu.'
            : 'Některé cviky se nepodařilo přidat. Zkus je přidat znovu.',
      );
    }
  }

  Future<String?> _editText({
    required String title,
    required String initial,
    String? hint,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zpět'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Uložit'),
          ),
        ],
      ),
      // Dialog ještě dobíhá animací s polem: uvolnit až potom.
    ).whenComplete(
      () => Future<void>.delayed(
        const Duration(milliseconds: 500),
        controller.dispose,
      ),
    );
  }

  Future<void> _save() async {
    try {
      await state.saveActive();
    } catch (_) {
      _snack('Změnu se nepodařilo uložit. Zkus to znovu.');
    }
  }

  Future<void> _rename(Workout workout) async {
    final name = await _editText(
      title: 'Název tréninku',
      initial: workout.name,
    );
    if (name == null || name.trim().isEmpty) return;
    workout.name = name.trim();
    await _save();
  }

  Future<void> _editWorkoutNote(Workout workout) async {
    final note = await _editText(
      title: 'Poznámka k tréninku',
      initial: workout.note,
      maxLines: 4,
    );
    if (note == null) return;
    workout.note = note.trim();
    await _save();
  }

  Future<void> _finish(Workout workout) async {
    if (_busy || _confirming) return;
    _confirming = true;
    try {
      await _finishFlow(workout);
    } finally {
      _confirming = false;
    }
  }

  /// Otevřený dialog dokončení: druhé klepnutí neotevře další.
  bool _confirming = false;

  Future<void> _finishFlow(Workout workout) async {
    FocusScope.of(context).unfocus();
    final working = workout.exercises
        .expand((e) => e.sets)
        .where((s) => !s.warmup && (s.done || s.reps > 0))
        .toList();
    final confirmed = working.where((s) => s.counts).length;
    // Bez potvrzené série není co uložit: nabídni pokračovat nebo zahodit,
    // ne dialog „Dokončit“ a po něm chybu.
    if (confirmed == 0) {
      if (mounted &&
          await confirmAction(
            context,
            title: 'Zatím žádná potvrzená série',
            message: 'Sérii potvrdíš zaškrtnutím vpravo. Trénink bez série se neuloží.',
            confirm: 'Zahodit trénink',
            cancel: 'Pokračovat',
            destructive: true,
          )) {
        await _discardNow();
      }
      return;
    }
    final pending = working.length - confirmed;
    if (pending > 0 &&
        (!await confirmAction(
              context,
              title: 'Dokončit trénink?',
              message:
                  'Hotovo $confirmed z ${working.length} sérií. '
                  'Nepotvrzené se neuloží.',
              confirm: 'Dokončit',
              cancel: 'Pokračovat',
            ) ||
            !mounted)) {
      return;
    }
    // „Ukládám…“ až po rozhodnutí, ne za otevřeným dialogem.
    setState(() => _busy = true);
    try {
      final result = await state.finishActive();
      if (!mounted) return;
      if (result.error != null) return _snack(result.error!);
      _hideUndo();
      Navigator.pop(context, result.workout);
    } catch (_) {
      _snack('Trénink se nepodařilo uložit. Zkus dokončení znovu.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    if (_busy) return;
    if (!await confirmAction(
      context,
      title: 'Zahodit trénink?',
      message: 'Rozepsaný trénink se smaže.',
      confirm: 'Zahodit',
      destructive: true,
    )) {
      return;
    }
    await _discardNow();
  }

  Future<void> _discardNow() async {
    try {
      await state.discardActive();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _snack('Trénink se nepodařilo zahodit. Zkus to znovu.');
    }
  }

  /// Smaže sérii a nabídne „Vrátit".
  Future<void> _removeSet(WorkoutExercise entry, SetEntry set) async {
    final sets = entry.sets;
    try {
      final index = await state.removeSet(entry, set);
      if (index < 0 || !mounted) return;
      showUndo(context, 'Série smazána', () async {
        try {
          final ok = await state.restoreSet(entry, set, index, sets: sets);
          if (!ok) _snack('Sérii už nejde vrátit.');
        } catch (_) {
          _snack('Sérii se nepodařilo vrátit.');
        }
      });
    } catch (_) {
      _snack('Sérii se nepodařilo smazat. Zkus to znovu.');
    }
  }

  /// Zavře nabídku „Vrátit" (po změně, po které už nedává smysl).
  void _hideUndo() => ScaffoldMessenger.of(context).hideCurrentSnackBar();

  Future<void> _exerciseMenu(WorkoutExercise entry, String action) async {
    final hasDone = entry.sets.any((s) => s.done);
    switch (action) {
      case 'note':
        final note = await _editText(
          title: 'Poznámka ke cviku',
          initial: entry.note,
          hint: 'např. nastavení stroje',
          maxLines: 3,
        );
        if (note == null) return;
        entry.note = note.trim();
        await _save();
      case 'replace':
        if (hasDone &&
            !await confirmAction(
              context,
              title: 'Nahradit cvik?',
              message: 'Potvrzené série tohoto cviku se smažou.',
              confirm: 'Nahradit',
              destructive: true,
            )) {
          return;
        }
        if (!mounted) return;
        final id = await pickAlternative(context, state, entry.exerciseId);
        if (id == null || !mounted) return;
        _hideUndo();
        try {
          await state.replaceExercise(entry, id);
        } catch (_) {
          _snack('Cvik se nepodařilo nahradit. Zkus to znovu.');
        }
      case 'warmups':
        try {
          final added = await state.addWarmups(entry);
          _snack(switch (added) {
            null => 'Rozcvička už je potvrzená, nebo chybí pracovní váha.',
            0 => 'Na takhle lehkou váhu rozcvička není potřeba.',
            1 => 'Přidána 1 rozcvičovací série.',
            final n when n < 5 => 'Přidány $n rozcvičovací série.',
            final n => 'Přidáno $n rozcvičovacích sérií.',
          });
        } catch (_) {
          _snack('Rozcvičku se nepodařilo přidat. Zkus to znovu.');
        }
      case 'rest':
        await _pickRest(entry.exerciseId);
      case 'plates':
        final next = entry.sets.where((s) => !s.warmup && !s.done);
        final any = entry.sets.where((s) => !s.warmup);
        final weight = next.isNotEmpty
            ? next.first.weight
            : any.isNotEmpty
            ? any.last.weight
            : 0.0;
        await showPlates(context, weight);
      case 'up' || 'down':
        try {
          await state.moveExercise(entry, action == 'up' ? -1 : 1);
        } catch (_) {
          _snack('Pořadí se nepodařilo uložit. Zkus to znovu.');
        }
      case 'reorder':
        await showReorderSheet(context, state);
      case 'remove':
        if (hasDone &&
            !await confirmAction(
              context,
              title: 'Odebrat cvik?',
              message: 'Potvrzené série tohoto cviku se smažou.',
              confirm: 'Odebrat',
              destructive: true,
            )) {
          return;
        }
        _hideUndo();
        try {
          await state.removeExercise(entry);
        } catch (_) {
          _snack('Cvik se nepodařilo odebrat. Zkus to znovu.');
        }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final workout = state.active;
      if (workout == null) return const Scaffold();
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final exercises = workout.exercises;
      return PopScope(
        canPop: !_busy,
        child: AbsorbPointer(
          absorbing: _busy,
          child: Scaffold(
            appBar: AppBar(
              // Šipka dolů trénink jen schová (běží dál v liště nad
              // navigací, jako v Hevy); zrušit jde z menu vpravo.
              leading: IconButton(
                tooltip: 'Skrýt trénink',
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
              // Název vlevo vedle šipky: na úzkém displeji se vejde víc.
              centerTitle: false,
              titleSpacing: 0,
              title: Semantics(
                container: true,
                button: true,
                hint: 'Přejmenovat trénink',
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    context.palette.controlRadius,
                  ),
                  onTap: () => _rename(workout),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      _Elapsed(workout.startedAt),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _finish(workout),
                  child: Text(_busy ? 'Ukládám…' : 'Dokončit'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Možnosti tréninku',
                  onSelected: (v) => switch (v) {
                    'rename' => _rename(workout),
                    'note' => _editWorkoutNote(workout),
                    _ => _discard(),
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Přejmenovat'),
                    ),
                    const PopupMenuItem(
                      value: 'note',
                      child: Text('Poznámka k tréninku'),
                    ),
                    PopupMenuItem(
                      value: 'discard',
                      child: Text(
                        'Zahodit trénink',
                        style: TextStyle(color: p.negative),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                Space.s,
                Space.page,
                Space.xxxl,
              ),
              children: [
                if (workout.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xs,
                      0,
                      Space.xs,
                      Space.m,
                    ),
                    child: Text(workout.note, style: text.bodySmall),
                  ),
                if (exercises.isEmpty)
                  const EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'Zatím žádný cvik',
                    message: 'Přidej první cvik a zapiš sérii.',
                  ),
                for (var i = 0; i < exercises.length; i++)
                  _ExerciseCard(
                    key: ObjectKey(exercises[i]),
                    state: state,
                    entry: exercises[i],
                    canMoveUp: i > 0,
                    canMoveDown: i < exercises.length - 1,
                    onMenu: (action) => _exerciseMenu(exercises[i], action),
                    onRemoveSet: (set) => _removeSet(exercises[i], set),
                    onError: _snack,
                  ),
                const SizedBox(height: Space.s),
                if (exercises.isEmpty)
                  PrimaryButton(
                    'Přidat cvik',
                    icon: Icons.add_rounded,
                    onPressed: _addExercises,
                  )
                else
                  SecondaryButton(
                    'Přidat cvik',
                    icon: Icons.add_rounded,
                    onPressed: _addExercises,
                  ),
              ],
            ),
            bottomNavigationBar: state.restEndsAt == null
                ? null
                : _RestBar(state: state, endsAt: state.restEndsAt!),
          ),
        ),
      );
    },
  );
}

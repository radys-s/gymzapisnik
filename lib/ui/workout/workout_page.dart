import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../coach/plates.dart';
import '../../coach/progression.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/parse.dart';
import '../../domain/last_delta.dart';
import '../../domain/models.dart';
import '../../domain/rpe.dart';
import '../../domain/set_match.dart';
import '../../domain/superset.dart';
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
            header: tr(
              'Pauza u cviku ${state.exercise(exerciseId).name}',
              'Rest for ${state.exercise(exerciseId).name}',
            ),
            footer: tr(
              'Platí pro tento cvik i v dalších trénincích.',
              'Applies to this exercise in future workouts too.',
            ),
            children: [
              for (final s in [0, 60, 90, 120, 150, 180, 240])
                GroupedRow(
                  title: s == 0
                      ? tr(
                          'Výchozí (${restLabel(base)})',
                          'Default (${restLabel(base)})',
                        )
                      : restLabel(s),
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
      _snack(
        tr(
          'Pauzu se nepodařilo uložit. Zkus to znovu.',
          'Could not save rest. Try again.',
        ),
      );
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
            ? tr(
                'Cvik se nepodařilo přidat. Zkus to znovu.',
                'Could not add the exercise. Try again.',
              )
            : tr(
                'Některé cviky se nepodařilo přidat. Zkus je přidat znovu.',
                'Could not add some exercises. Try adding them again.',
              ),
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
            child: Text(tr('Zpět', 'Back')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(tr('Uložit', 'Save')),
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
      _snack(
        tr(
          'Změnu se nepodařilo uložit. Zkus to znovu.',
          'Could not save the change. Try again.',
        ),
      );
    }
  }

  Future<void> _rename(Workout workout) async {
    final name = await _editText(
      title: tr('Název tréninku', 'Workout name'),
      initial: workout.name,
    );
    if (name == null || name.trim().isEmpty) return;
    workout.name = name.trim();
    await _save();
  }

  Future<void> _editWorkoutNote(Workout workout) async {
    final note = await _editText(
      title: tr('Poznámka k tréninku', 'Workout note'),
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
            title: tr('Zatím žádná potvrzená série', 'No confirmed sets yet'),
            message: tr(
              'Sérii potvrdíš zaškrtnutím vpravo. Trénink bez série se neuloží.',
              'Confirm a set with the checkmark on the right. A workout without sets won\'t be saved.',
            ),
            confirm: tr('Zahodit trénink', 'Discard workout'),
            cancel: tr('Pokračovat', 'Continue'),
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
              title: tr('Dokončit trénink?', 'Finish workout?'),
              message: tr(
                'Hotovo $confirmed z ${working.length} sérií. '
                    'Nepotvrzené se neuloží.',
                'Done $confirmed of ${working.length} sets. '
                    'Unconfirmed sets won\'t be saved.',
              ),
              confirm: tr('Dokončit', 'Finish'),
              cancel: tr('Pokračovat', 'Continue'),
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
      _snack(
        tr(
          'Trénink se nepodařilo uložit. Zkus dokončení znovu.',
          'Could not save the workout. Try finishing again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    if (_busy) return;
    if (!await confirmAction(
      context,
      title: tr('Zahodit trénink?', 'Discard workout?'),
      message: tr(
        'Rozepsaný trénink se smaže.',
        'The workout in progress will be deleted.',
      ),
      confirm: tr('Zahodit', 'Discard'),
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
      _snack(
        tr(
          'Trénink se nepodařilo zahodit. Zkus to znovu.',
          'Could not discard the workout. Try again.',
        ),
      );
    }
  }

  /// Smaže sérii a nabídne „Vrátit".
  Future<void> _removeSet(WorkoutExercise entry, SetEntry set) async {
    final sets = entry.sets;
    try {
      final index = await state.removeSet(entry, set);
      if (index < 0 || !mounted) return;
      showUndo(context, tr('Série smazána', 'Set deleted'), () async {
        try {
          final ok = await state.restoreSet(entry, set, index, sets: sets);
          if (!ok)
            _snack(
              tr('Sérii už nejde vrátit.', 'Can\'t restore the set anymore.'),
            );
        } catch (_) {
          _snack(
            tr('Sérii se nepodařilo vrátit.', 'Could not restore the set.'),
          );
        }
      });
    } catch (_) {
      _snack(
        tr(
          'Sérii se nepodařilo smazat. Zkus to znovu.',
          'Could not delete the set. Try again.',
        ),
      );
    }
  }

  /// Zavře nabídku „Vrátit" (po změně, po které už nedává smysl).
  void _hideUndo() => ScaffoldMessenger.of(context).hideCurrentSnackBar();

  Future<void> _exerciseMenu(WorkoutExercise entry, String action) async {
    final hasDone = entry.sets.any((s) => s.done);
    switch (action) {
      case 'note':
        final note = await _editText(
          title: tr('Poznámka ke cviku', 'Exercise note'),
          initial: entry.note,
          hint: tr('např. nastavení stroje', 'e.g. machine setting'),
          maxLines: 3,
        );
        if (note == null) return;
        entry.note = note.trim();
        await _save();
      case 'pin':
        final pinned = await _editText(
          title: tr('Připnutá poznámka', 'Pinned note'),
          initial: state.profile.exerciseNote(entry.exerciseId) ?? '',
          hint: tr(
            'ukáže se v každém tréninku, např. sedačka 4',
            'shows in every workout, e.g. seat 4',
          ),
          maxLines: 3,
        );
        if (pinned == null) return;
        try {
          await state.setExerciseNote(entry.exerciseId, pinned);
        } catch (_) {
          _snack(
            tr(
              'Poznámku se nepodařilo uložit. Zkus to znovu.',
              'Could not save the note. Try again.',
            ),
          );
        }
      case 'superset':
        try {
          if (!await state.linkSuperset(entry)) {
            _snack(
              tr(
                'Pod tímto cvikem už žádný další není.',
                'There\'s no exercise below this one.',
              ),
            );
          }
        } catch (_) {
          _snack(
            tr(
              'Supersérii se nepodařilo uložit. Zkus to znovu.',
              'Could not save the superset. Try again.',
            ),
          );
        }
      case 'unsuperset':
        try {
          await state.unlinkSuperset(entry);
        } catch (_) {
          _snack(
            tr(
              'Supersérii se nepodařilo zrušit. Zkus to znovu.',
              'Could not remove the superset. Try again.',
            ),
          );
        }
      case 'replace':
        if (hasDone &&
            !await confirmAction(
              context,
              title: tr('Nahradit cvik?', 'Replace exercise?'),
              message: tr(
                'Potvrzené série tohoto cviku se smažou.',
                'Confirmed sets for this exercise will be deleted.',
              ),
              confirm: tr('Nahradit', 'Replace'),
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
          _snack(
            tr(
              'Cvik se nepodařilo nahradit. Zkus to znovu.',
              'Could not replace the exercise. Try again.',
            ),
          );
        }
      case 'warmups':
        try {
          final added = await state.addWarmups(entry);
          _snack(switch (added) {
            null => tr(
              'Rozcvička už je potvrzená, nebo chybí pracovní váha.',
              'Warm-up already confirmed, or working weight is missing.',
            ),
            0 => tr(
              'Na takhle lehkou váhu rozcvička není potřeba.',
              'No warm-up needed for this light a weight.',
            ),
            1 => tr('Přidána 1 rozcvičovací série.', 'Added 1 warm-up set.'),
            final n when n < 5 => tr(
              'Přidány $n rozcvičovací série.',
              'Added $n warm-up sets.',
            ),
            final n => tr(
              'Přidáno $n rozcvičovacích sérií.',
              'Added $n warm-up sets.',
            ),
          });
        } catch (_) {
          _snack(
            tr(
              'Rozcvičku se nepodařilo přidat. Zkus to znovu.',
              'Could not add warm-up sets. Try again.',
            ),
          );
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
          _snack(
            tr(
              'Pořadí se nepodařilo uložit. Zkus to znovu.',
              'Could not save the order. Try again.',
            ),
          );
        }
      case 'reorder':
        await showReorderSheet(context, state);
      case 'remove':
        if (hasDone &&
            !await confirmAction(
              context,
              title: tr('Odebrat cvik?', 'Remove exercise?'),
              message: tr(
                'Potvrzené série tohoto cviku se smažou.',
                'Confirmed sets for this exercise will be deleted.',
              ),
              confirm: tr('Odebrat', 'Remove'),
              destructive: true,
            )) {
          return;
        }
        _hideUndo();
        try {
          await state.removeExercise(entry);
        } catch (_) {
          _snack(
            tr(
              'Cvik se nepodařilo odebrat. Zkus to znovu.',
              'Could not remove the exercise. Try again.',
            ),
          );
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
      // Série, na které uživatel je: první nepotvrzená v pořadí cviků.
      // V supersérii se střídá, tam proužek drží první cvik (záměrně jednoduché).
      final current = exercises
          .expand((e) => e.sets)
          .where((s) => !s.done)
          .firstOrNull;
      final slots = supersetSlots(exercises);
      return PopScope(
        canPop: !_busy,
        child: AbsorbPointer(
          absorbing: _busy,
          child: Scaffold(
            appBar: AppBar(
              // Šipka dolů trénink jen schová (běží dál v liště nad
              // navigací, jako v Hevy); zrušit jde z menu vpravo.
              leading: IconButton(
                tooltip: tr('Skrýt trénink', 'Hide workout'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
              // Název vlevo vedle šipky: na úzkém displeji se vejde víc.
              centerTitle: false,
              titleSpacing: 0,
              title: Semantics(
                container: true,
                button: true,
                hint: tr('Přejmenovat trénink', 'Rename workout'),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    context.palette.controlRadius,
                  ),
                  onTap: () => _rename(workout),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: minTap),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        workout.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: FilledButton(
                    onPressed: () => _finish(workout),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      _busy
                          ? tr('Ukládám…', 'Saving…')
                          : tr('Dokončit', 'Finish'),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: tr('Možnosti tréninku', 'Workout options'),
                  onSelected: (v) => switch (v) {
                    'rename' => _rename(workout),
                    'note' => _editWorkoutNote(workout),
                    _ => _discard(),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(tr('Přejmenovat', 'Rename')),
                    ),
                    PopupMenuItem(
                      value: 'note',
                      child: Text(tr('Poznámka k tréninku', 'Workout note')),
                    ),
                    PopupMenuItem(
                      value: 'discard',
                      child: Text(
                        tr('Zahodit trénink', 'Discard workout'),
                        style: TextStyle(color: p.negative),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                _SessionStrip(workout),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: Space.xxxl),
                    children: [
                      if (workout.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.page,
                            Space.m,
                            Space.page,
                            0,
                          ),
                          child: Text(workout.note, style: text.bodySmall),
                        ),
                      if (exercises.isEmpty)
                        EmptyState(
                          icon: Icons.fitness_center_rounded,
                          title: tr('Zatím žádný cvik', 'No exercises yet'),
                          message: tr(
                            'Přidej první cvik a zapiš sérii.',
                            'Add your first exercise and log a set.',
                          ),
                        ),
                      for (var i = 0; i < exercises.length; i++)
                        _ExerciseCard(
                          current: current,
                          superset: slots[i],
                          key: ObjectKey(exercises[i]),
                          state: state,
                          entry: exercises[i],
                          canMoveUp: i > 0,
                          canMoveDown: i < exercises.length - 1,
                          onMenu: (action) =>
                              _exerciseMenu(exercises[i], action),
                          onRemoveSet: (set) => _removeSet(exercises[i], set),
                          onError: _snack,
                        ),
                      const SizedBox(height: Space.l),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.page,
                        ),
                        child: exercises.isEmpty
                            ? PrimaryButton(
                                tr('Přidat cvik', 'Add exercise'),
                                icon: Icons.add_rounded,
                                onPressed: _addExercises,
                              )
                            : SecondaryButton(
                                tr('Přidat cvik', 'Add exercise'),
                                icon: Icons.add_rounded,
                                onPressed: _addExercises,
                              ),
                      ),
                    ],
                  ),
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

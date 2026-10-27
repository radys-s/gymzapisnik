import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../coach/plates.dart';
import '../../coach/progression.dart';
import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../exercises/exercise_detail_page.dart';
import '../widgets/exercise_media.dart';
import 'alternatives_page.dart';
import 'exercise_picker.dart';
import 'plates_sheet.dart';
import 'set_sheet.dart';

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
    if (_busy) return;
    setState(() => _busy = true);
    try {
      FocusScope.of(context).unfocus();
      final pending = workout.exercises
          .expand((e) => e.sets)
          .where((s) => !s.done && s.reps > 0)
          .length;
      if (pending > 0 &&
          !await confirmAction(
            context,
            title: 'Dokončit trénink?',
            message: 'Nepotvrzené série ($pending) se neuloží.',
            confirm: 'Dokončit',
          )) {
        return;
      }
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
              // Název vlevo vedle křížku: na úzkém displeji se vejde víc.
              centerTitle: false,
              titleSpacing: 0,
              title: Semantics(
                container: true,
                button: true,
                hint: 'Přejmenovat trénink',
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.control),
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

/// Uplynulý čas tréninku; překresluje jen sebe.
class _Elapsed extends StatefulWidget {
  final DateTime start;
  const _Elapsed(this.start);

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    final text = s >= 3600
        ? '${s ~/ 3600}:${two(s % 3600 ~/ 60)}:${two(s % 60)}'
        : '${s ~/ 60}:${two(s % 60)}';
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontFeatures: tabular),
    );
  }
}

/// Odpočet pauzy. Konec se počítá z časového razítka, takže sedí i po
/// návratu do aplikace. Na konci zavibruje a pípne (jen když je otevřená).
class _RestBar extends StatefulWidget {
  final AppState state;
  final DateTime endsAt;
  const _RestBar({required this.state, required this.endsAt});

  @override
  State<_RestBar> createState() => _RestBarState();
}

class _RestBarState extends State<_RestBar> {
  late final Timer timer;
  DateTime? _alertedFor;

  /// Jak dlouho po konci zůstane lišta „Pauza hotová“.
  static const _linger = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    // Pauza, která skončila dřív, než se lišta ukázala, už nepípá.
    if (!widget.endsAt.isAfter(DateTime.now())) _alertedFor = widget.endsAt;
    timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void didUpdateWidget(_RestBar old) {
    super.didUpdateWidget(old);
    if (old.endsAt != widget.endsAt && !widget.endsAt.isAfter(DateTime.now())) {
      _alertedFor = widget.endsAt;
    }
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final end = widget.endsAt;
    if (!end.isAfter(now) && _alertedFor != end) {
      _alertedFor = end;
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    }
    if (now.isAfter(end.add(_linger))) {
      widget.state.skipRest();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    final seconds = (left.inMilliseconds / 1000).ceil();
    final finished = seconds <= 0;
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Plovoucí tableta: ve světlém režimu tmavá, v tmavém bílá.
    final bg = dark ? Colors.white : const Color(0xFF18181A);
    final fg = dark ? Colors.black : Colors.white;
    final chipFg = finished ? p.onGradient : fg;
    final text = finished
        ? 'Pauza hotová'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    Widget chip(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: chipFg,
          backgroundColor: chipFg.withValues(alpha: 0.12),
          minimumSize: const Size(minTap, minTap),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontFeatures: tabular),
        ),
        child: Text(label),
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.m, Space.xs, Space.m, Space.s),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.hero),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            // Hotová pauza se rozsvítí přechodem motivu.
            decoration: BoxDecoration(gradient: finished ? p.linear : null),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: finished ? p.onGradient : fg,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(
                      text,
                      semanticsLabel: finished ? text : 'Pauza $text',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: finished ? p.onGradient : fg,
                            fontFeatures: tabular,
                          ),
                    ),
                  ),
                  // Úzký displej nebo velké písmo: tlačítka se zmenší.
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!finished) ...[
                            chip(
                              '−15',
                              () => widget.state.adjustRest(
                                const Duration(seconds: -15),
                              ),
                            ),
                            chip(
                              '+15',
                              () => widget.state.adjustRest(
                                const Duration(seconds: 15),
                              ),
                            ),
                          ],
                          chip(
                            finished ? 'Zavřít' : 'Přeskočit',
                            widget.state.skipRest,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vysvětlení návrhu kouče uložené u cviku (jen u tréninku podle splitu).
String? _coachReason(WorkoutExercise entry) {
  final coach = entry.extra[coachKey];
  return coach is Map && coach['reason'] is String
      ? coach['reason'] as String
      : null;
}

/// Šířky sloupců řádku série (záhlaví a řádky musí sedět).
const _typeWidth = minTap;
const _doneWidth = 52.0;
const _badgeWidth = 30.0;

/// Odsazení od okraje zvýraznění série: odznak vlevo, ✓ vpravo i řádek
/// +/− pod sérií mají od kraje stejnou mezeru.
const _edgeInset = (_typeWidth - _badgeWidth) / 2;

class _ExerciseCard extends StatelessWidget {
  final AppState state;
  final WorkoutExercise entry;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String> onMenu;
  final ValueChanged<SetEntry> onRemoveSet;
  final ValueChanged<String> onError;

  const _ExerciseCard({
    super.key,
    required this.state,
    required this.entry,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMenu,
    required this.onRemoveSet,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final exercise = state.exercise(entry.exerciseId);
    final previous = state.previousFor(entry);
    final bodyweight = exercise.type == ExerciseType.bodyweight;
    var workingIndex = 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(
          Space.m,
          Space.xs,
          Space.xs,
          Space.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  // Fotka a název otevřou kartu cviku: technika, svaly.
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.control),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExerciseDetailPage(state, exercise.id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.xs,
                        vertical: Space.xs,
                      ),
                      child: Row(
                        children: [
                          ExerciseThumb(exercise.id, size: 36),
                          const SizedBox(width: Space.s),
                          Expanded(
                            child: Semantics(
                              container: true,
                              header: true,
                              hint: 'Otevře techniku cviku',
                              child: Text(
                                exercise.name,
                                style: text.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Vyměnit cvik',
                  onPressed: () => onMenu('replace'),
                  icon: Icon(Icons.swap_horiz_rounded, color: p.accent),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Možnosti cviku',
                  icon: Icon(Icons.more_horiz_rounded, color: p.secondaryLabel),
                  onSelected: onMenu,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'note', child: Text('Poznámka')),
                    if (!bodyweight) ...[
                      const PopupMenuItem(
                        value: 'warmups',
                        child: Text('Přidat rozcvičku'),
                      ),
                      if (usesPlates(exercise.id, custom: exercise.custom))
                        const PopupMenuItem(
                          value: 'plates',
                          child: Text('Kotouče na činku'),
                        ),
                    ],
                    if (canMoveUp)
                      const PopupMenuItem(
                        value: 'up',
                        child: Text('Posunout výš'),
                      ),
                    if (canMoveDown)
                      const PopupMenuItem(
                        value: 'down',
                        child: Text('Posunout níž'),
                      ),
                    if (canMoveUp || canMoveDown)
                      const PopupMenuItem(
                        value: 'reorder',
                        child: Text('Seřadit cviky'),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Odebrat',
                        style: TextStyle(color: p.negative),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_coachReason(entry) case final reason?)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xs,
                  0,
                  Space.s,
                  Space.s,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 16,
                      color: p.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason, style: text.bodySmall)),
                  ],
                ),
              ),
            if (entry.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xs,
                  0,
                  Space.s,
                  Space.s,
                ),
                child: Text(entry.note, style: text.bodySmall),
              ),
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(right: _edgeInset),
                child: DefaultTextStyle.merge(
                  style: text.labelMedium,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: _typeWidth,
                        child: Text('Série', textAlign: TextAlign.center),
                      ),
                      const Expanded(flex: 3, child: Text('Minule')),
                      Expanded(
                        flex: 3,
                        child: Text(
                          bodyweight ? '+kg' : 'kg',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Text('opak.', textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: _doneWidth),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            for (var i = 0; i < entry.sets.length; i++)
              _SetRow(
                exercise: exercise.name,
                key: ObjectKey(entry.sets[i]),
                state: state,
                set: entry.sets[i],
                label: entry.sets[i].warmup ? 'R' : '${++workingIndex}',
                bodyweight: bodyweight,
                previous: previous[i],
                onRemove: () => onRemoveSet(entry.sets[i]),
                onError: onError,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await state.addSet(entry);
                  } catch (_) {
                    onError('Sérii se nepodařilo přidat. Zkus to znovu.');
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Série'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final AppState state;
  final SetEntry set;
  final String label;
  final bool bodyweight;
  final SetEntry? previous;
  final VoidCallback onRemove;
  final ValueChanged<String> onError;

  /// Název cviku do nadpisu listu úprav.
  final String exercise;

  const _SetRow({
    super.key,
    this.exercise = '',
    required this.state,
    required this.set,
    required this.label,
    required this.bodyweight,
    required this.previous,
    required this.onRemove,
    required this.onError,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final weight = TextEditingController(text: _kgText(widget.set.weight));
  late final reps = TextEditingController(text: _repsText(widget.set.reps));
  bool _saving = false;
  Timer? _toggleCooldown;

  static String _kgText(double v) => v == 0 ? '' : formatKg(v);
  static String _repsText(int v) => v == 0 ? '' : '$v';

  /// Název série pro čtečku obrazovky.
  String get _name => widget.set.warmup ? 'Rozcvička' : 'Série ${widget.label}';

  @override
  void dispose() {
    _toggleCooldown?.cancel();
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  Future<void> _persist(Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {
      if (mounted) {
        widget.onError(
          'Změnu se nepodařilo uložit. Zkus ji znovu; aplikaci zatím nezavírej.',
        );
      }
    }
  }

  Future<void> _toggleDone() async {
    if (_saving || (_toggleCooldown?.isActive ?? false)) {
      return;
    }
    _toggleCooldown = Timer(const Duration(milliseconds: 300), () {});
    setState(() => _saving = true);
    try {
      final error = await widget.state.toggleDone(widget.set);
      if (error != null && mounted) widget.onError(error);
      final records = widget.state.liveRecords(widget.set);
      if (error == null && widget.set.done && mounted) {
        if (records.isEmpty) {
          HapticFeedback.selectionClick();
        } else {
          HapticFeedback.heavyImpact();
          _celebrate(records);
        }
      }
    } catch (_) {
      if (mounted) {
        widget.onError(
          'Sérii se nepodařilo uložit. Zkus zápis znovu; aplikaci zatím nezavírej.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _celebrate(List<RecordKind> records) {
    final p = context.palette;
    // Bez hideCurrentSnackBar: nabídka „Vrátit“ po smazání musí zůstat.
    // Krátké trvání, ať se série rekordů nehromadí ve frontě.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: p.gold),
            const SizedBox(width: Space.s),
            Expanded(
              child: Text(
                'Nový osobní rekord: '
                '${records.map((r) => r.label.toLowerCase()).join(', ')}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List s velkými čísly a − / +. Změny se ukládají hned jako psaní.
  Future<void> _openSheet({bool focusReps = false}) => showSetSheet(
    context,
    title: widget.exercise.isEmpty ? _name : '${widget.exercise} · $_name',
    weight: weight.text,
    reps: reps.text,
    step: widget.state.profile.weightStep,
    bodyweight: widget.bodyweight,
    focusReps: focusReps,
    // Zapisuje rovnou do série, i kdyby se řádek mezitím přestavěl.
    // List čísla ověří předem; chybu uložení ukáže sám.
    onChanged: (w, r) async {
      final set = widget.set;
      final state = widget.state;
      set
        ..weight = parseNum(w) ?? 0
        ..reps = int.tryParse(r.trim()) ?? 0;
      if (mounted) {
        weight.text = w;
        reps.text = r;
      }
      try {
        await state.saveActive();
        return true;
      } catch (_) {
        return false;
      }
    },
  );

  void _typeMenu(String action) => switch (action) {
    'working' => _persist(() => widget.state.setWarmup(widget.set, false)),
    'warmup' => _persist(() => widget.state.setWarmup(widget.set, true)),
    _ => widget.onRemove(),
  };

  Widget _field(
    TextEditingController c, {
    required String label,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: ListenableBuilder(
      listenable: c,
      builder: (context, field) => Semantics(
        container: true,
        label: label,
        value: c.text.isEmpty ? '0' : c.text,
        hint: 'Otevře úpravu série',
        button: true,
        onTap: () => _openSheet(focusReps: !decimal),
        child: ExcludeSemantics(child: field),
      ),
      // Pole jen ukazuje hodnotu, klepnutí otevře list s − / +.
      child: TextField(
        controller: c,
        readOnly: true,
        // Bez fokusu: po zavření listu nezůstane pole zvýrazněné.
        canRequestFocus: false,
        showCursor: false,
        enableInteractiveSelection: false,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontFeatures: tabular),
        decoration: const InputDecoration(
          hintText: '0',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
        onTap: () => _openSheet(focusReps: !decimal),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final set = widget.set;
    final prev = widget.previous;
    final kgLabel = widget.bodyweight ? 'Přidaná váha v kg' : 'Váha v kg';
    final record = set.done && widget.state.liveRecords(set).isNotEmpty;
    return Dismissible(
      key: ObjectKey(set),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.xl),
        decoration: BoxDecoration(
          color: p.negative,
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => widget.onRemove(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.only(right: _edgeInset),
        decoration: BoxDecoration(
          color: set.done ? p.accent.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _typeWidth,
              height: minTap,
              // Vlastní uzel, jinak se tlačítko slije s textem „Minule".
              child: Semantics(
                container: true,
                button: true,
                child: PopupMenuButton<String>(
                  tooltip: '$_name, změnit typ',
                  padding: EdgeInsets.zero,
                  onSelected: _typeMenu,
                  itemBuilder: (_) => [
                    CheckedPopupMenuItem(
                      value: 'working',
                      checked: !set.warmup,
                      child: const Text('Pracovní série'),
                    ),
                    CheckedPopupMenuItem(
                      value: 'warmup',
                      checked: set.warmup,
                      child: const Text('Rozcvička'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Smazat sérii',
                        style: TextStyle(color: p.negative),
                      ),
                    ),
                  ],
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: _badgeWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: record
                            ? p.gold.withValues(alpha: 0.2)
                            : set.warmup
                            ? p.accent.withValues(alpha: 0.16)
                            : p.fill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // Rekordní série má místo čísla pohár.
                      child: record
                          ? Icon(
                              Icons.emoji_events_rounded,
                              size: 18,
                              color: p.gold,
                              semanticLabel: 'Osobní rekord',
                            )
                          : Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: text.titleSmall?.copyWith(
                                color: set.warmup ? p.accent : p.label,
                                fontFeatures: tabular,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              // Celé číslo i na úzkém displeji: radši menší než useknuté.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  prev == null ? '–' : '${formatKg(prev.weight)}×${prev.reps}',
                  semanticsLabel: prev == null
                      ? 'Minule nic'
                      : 'Minule ${formatKg(prev.weight)} kg, ${prev.reps} opakování',
                  maxLines: 1,
                  style: text.bodyMedium?.copyWith(
                    color: p.secondaryLabel,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _field(weight, label: '$kgLabel, $_name', decimal: true),
            ),
            Expanded(flex: 3, child: _field(reps, label: 'Opakování, $_name')),
            Container(
              width: _doneWidth,
              height: 48,
              padding: const EdgeInsets.only(left: Space.xs),
              // Potvrzená série svítí přechodem motivu.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: set.done ? p.linear : null,
                  color: set.done ? null : p.fill,
                  borderRadius: BorderRadius.circular(Radii.control),
                ),
                child: IconButton(
                  tooltip: set.done ? 'Zrušit potvrzení' : 'Potvrdit sérii',
                  onPressed: _saving ? null : _toggleDone,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: set.done ? p.onGradient : p.secondaryLabel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.control),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List se seznamem cviků tréninku; pořadí se mění tažením za úchyt.
Future<void> showReorderSheet(BuildContext context, AppState state) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReorderSheet(state),
    );

class _ReorderSheet extends StatelessWidget {
  final AppState state;
  const _ReorderSheet(this.state);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final exercises = state.active?.exercises ?? const <WorkoutExercise>[];
      final text = Theme.of(context).textTheme;
      final p = context.palette;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                0,
                Space.page,
                Space.xs,
              ),
              child: Text('Seřadit cviky', style: text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                0,
                Space.page,
                Space.m,
              ),
              child: Text(
                'Podrž úchyt vpravo a přetáhni cvik na nové místo.',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(bottom: Space.xl),
                itemCount: exercises.length,
                onReorderItem: (from, to) async {
                  try {
                    await state.reorderExercise(from, to);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pořadí se nepodařilo uložit. Zkus to znovu.',
                          ),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context, i) {
                  final entry = exercises[i];
                  final exercise = state.exercise(entry.exerciseId);
                  final done = entry.sets.where((s) => s.done && !s.warmup);
                  return ListTile(
                    key: ObjectKey(entry),
                    leading: ExerciseThumb(exercise.id, size: 36),
                    title: Text(exercise.name),
                    subtitle: Text(
                      done.isEmpty
                          ? 'Zatím bez potvrzené série'
                          : 'Hotovo ${done.length} z ${entry.sets.where((s) => !s.warmup).length}',
                    ),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: Semantics(
                        label: 'Přetáhnout ${exercise.name}',
                        child: const Padding(
                          padding: EdgeInsets.all(Space.s),
                          child: Icon(Icons.drag_handle_rounded),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

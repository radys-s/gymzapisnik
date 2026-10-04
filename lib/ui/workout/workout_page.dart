import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import 'exercise_picker.dart';

/// Rozepsaný trénink. Každá změna se hned ukládá (přežije zavření aplikace).
class WorkoutPage extends StatefulWidget {
  final AppState state;
  const WorkoutPage(this.state, {super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  AppState get state => widget.state;

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _pickExercise() => Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => ExercisePickerPage(state)),
  );

  Future<void> _addExercise() async {
    final id = await _pickExercise();
    if (id != null) await state.addExercise(id);
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
    ).whenComplete(controller.dispose);
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zpět'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _rename(Workout workout) async {
    final name = await _editText(
      title: 'Název tréninku',
      initial: workout.name,
    );
    if (name == null || name.trim().isEmpty) return;
    workout.name = name.trim();
    await state.saveActive();
  }

  Future<void> _editWorkoutNote(Workout workout) async {
    final note = await _editText(
      title: 'Poznámka k tréninku',
      initial: workout.note,
      maxLines: 4,
    );
    if (note == null) return;
    workout.note = note.trim();
    await state.saveActive();
  }

  Future<void> _finish(Workout workout) async {
    FocusScope.of(context).unfocus();
    final pending = workout.exercises
        .expand((e) => e.sets)
        .where((s) => !s.done && s.reps > 0)
        .length;
    if (pending > 0 &&
        !await _confirm(
          'Dokončit trénink?',
          'Nepotvrzené série ($pending) se neuloží.',
          'Dokončit',
        )) {
      return;
    }
    final result = await state.finishActive();
    if (!mounted) return;
    if (result.error != null) return _snack(result.error!);
    Navigator.pop(context, result.workout);
  }

  Future<void> _discard() async {
    if (!await _confirm(
      'Zahodit trénink?',
      'Rozepsaný trénink se smaže.',
      'Zahodit',
    )) {
      return;
    }
    await state.discardActive();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _exerciseMenu(WorkoutExercise entry, String action) async {
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
        await state.saveActive();
      case 'replace':
        final id = await _pickExercise();
        if (id != null) await state.replaceExercise(entry, id);
      case 'remove':
        if (entry.sets.any((s) => s.done) &&
            !await _confirm(
              'Odebrat cvik?',
              'Potvrzené série tohoto cviku se smažou.',
              'Odebrat',
            )) {
          return;
        }
        await state.removeExercise(entry);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final workout = state.active;
      if (workout == null) return const Scaffold();
      return Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: () => _rename(workout),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.name, overflow: TextOverflow.ellipsis),
                _Elapsed(workout.startedAt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _finish(workout),
              child: const Text('Dokončit'),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'rename' => _rename(workout),
                'note' => _editWorkoutNote(workout),
                _ => _discard(),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Přejmenovat')),
                PopupMenuItem(
                  value: 'note',
                  child: Text('Poznámka k tréninku'),
                ),
                PopupMenuItem(value: 'discard', child: Text('Zahodit trénink')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
          children: [
            if (workout.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  workout.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (workout.exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text('Přidej první cvik.', textAlign: TextAlign.center),
              ),
            for (final entry in workout.exercises)
              _ExerciseCard(
                key: ObjectKey(entry),
                state: state,
                entry: entry,
                onMenu: (action) => _exerciseMenu(entry, action),
                onError: _snack,
              ),
          ],
        ),
        bottomNavigationBar: state.restEndsAt == null
            ? null
            : _RestBar(state: state, endsAt: state.restEndsAt!),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExercise,
          icon: const Icon(Icons.add),
          label: const Text('Přidat cvik'),
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
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
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
    final scheme = Theme.of(context).colorScheme;
    final text = finished
        ? 'Pauza hotová'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Material(
      color: finished ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  semanticsLabel: finished ? text : 'Pauza $text',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!finished) ...[
                TextButton(
                  onPressed: () =>
                      widget.state.adjustRest(const Duration(seconds: -15)),
                  child: const Text('−15'),
                ),
                TextButton(
                  onPressed: () =>
                      widget.state.adjustRest(const Duration(seconds: 15)),
                  child: const Text('+15'),
                ),
              ],
              TextButton(
                onPressed: widget.state.skipRest,
                child: Text(finished ? 'Zavřít' : 'Přeskočit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final AppState state;
  final WorkoutExercise entry;
  final ValueChanged<String> onMenu;
  final ValueChanged<String> onError;

  const _ExerciseCard({
    super.key,
    required this.state,
    required this.entry,
    required this.onMenu,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = state.exercise(entry.exerciseId);
    final last = state.lastSetsOf(entry.exerciseId);
    final bodyweight = exercise.type == ExerciseType.bodyweight;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    var workingIndex = 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Možnosti cviku',
                  onSelected: onMenu,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'note', child: Text('Poznámka')),
                    PopupMenuItem(value: 'replace', child: Text('Nahradit')),
                    PopupMenuItem(value: 'remove', child: Text('Odebrat')),
                  ],
                ),
              ],
            ),
            if (entry.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  entry.note,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: muted, fontSize: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 36, child: Text('Série')),
                    const Expanded(flex: 3, child: Text('Minule')),
                    Expanded(flex: 3, child: Text(bodyweight ? '+kg' : 'kg')),
                    const Expanded(flex: 3, child: Text('Opak.')),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < entry.sets.length; i++)
              _SetRow(
                key: ObjectKey(entry.sets[i]),
                state: state,
                entry: entry,
                set: entry.sets[i],
                label: entry.sets[i].warmup ? 'R' : '${++workingIndex}',
                previous: i < last.length ? last[i] : null,
                onError: onError,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => state.addSet(entry),
                icon: const Icon(Icons.add),
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
  final WorkoutExercise entry;
  final SetEntry set;
  final String label;
  final SetEntry? previous;
  final ValueChanged<String> onError;

  const _SetRow({
    super.key,
    required this.state,
    required this.entry,
    required this.set,
    required this.label,
    required this.previous,
    required this.onError,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final weight = TextEditingController(text: _kgText(widget.set.weight));
  late final reps = TextEditingController(text: _repsText(widget.set.reps));
  Timer? _debounce;

  static String _kgText(double v) => v == 0 ? '' : formatKg(v);
  static String _repsText(int v) => v == 0 ? '' : '$v';

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      widget.state.saveActive();
    }
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  void _changed() {
    widget.set
      ..weight = parseNum(weight.text) ?? 0
      ..reps = int.tryParse(reps.text.trim()) ?? 0;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      widget.state.saveActive,
    );
  }

  Future<void> _toggleDone() async {
    _changed();
    _debounce?.cancel();
    final error = await widget.state.toggleDone(widget.set);
    if (error != null) widget.onError(error);
  }

  Widget _field(TextEditingController c, String hint, {bool decimal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: c,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
            ),
          ],
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onTap: () => c.selection = TextSelection(
            baseOffset: 0,
            extentOffset: c.text.length,
          ),
          onChanged: (_) => _changed(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final scheme = Theme.of(context).colorScheme;
    final prev = widget.previous;
    return Dismissible(
      key: ObjectKey(set),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: scheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) {
        _debounce?.cancel();
        widget.state.removeSet(widget.entry, set);
      },
      child: Container(
        color: set.done ? scheme.primary.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: InkWell(
                onTap: () => widget.state.toggleWarmup(set),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    widget.label,
                    semanticsLabel: set.warmup
                        ? 'Rozcvička, přepnout na pracovní'
                        : 'Série ${widget.label}, přepnout na rozcvičku',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: set.warmup ? scheme.tertiary : null,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                prev == null ? '–' : '${formatKg(prev.weight)}×${prev.reps}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(flex: 3, child: _field(weight, '0', decimal: true)),
            Expanded(flex: 3, child: _field(reps, '0')),
            SizedBox(
              width: 52,
              height: 48,
              child: set.done
                  ? IconButton.filled(
                      tooltip: 'Zrušit potvrzení',
                      onPressed: _toggleDone,
                      icon: const Icon(Icons.check),
                    )
                  : IconButton.outlined(
                      tooltip: 'Potvrdit sérii',
                      onPressed: _toggleDone,
                      icon: const Icon(Icons.check),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

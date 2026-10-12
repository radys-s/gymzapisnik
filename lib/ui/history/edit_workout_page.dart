import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Úprava dokončeného tréninku. Pracuje na kopii; uloží až „Uložit".
class EditWorkoutPage extends StatefulWidget {
  final AppState state;
  final Workout workout;
  const EditWorkoutPage(this.state, this.workout, {super.key});

  @override
  State<EditWorkoutPage> createState() => _EditWorkoutPageState();
}

class _EditWorkoutPageState extends State<EditWorkoutPage> {
  late final Workout draft = widget.workout.copy();
  late final name = TextEditingController(text: draft.name);
  late final note = TextEditingController(text: draft.note);
  bool saving = false;
  bool allowExit = false;
  bool leaving = false;

  bool get dirty {
    final current = draft.copy()
      ..name = name.text
      ..note = note.text;
    return jsonEncode(current.toJson()) != jsonEncode(widget.workout.toJson());
  }

  @override
  void initState() {
    super.initState();
    name.addListener(_changed);
    note.addListener(_changed);
  }

  void _changed() => setState(() {});

  Future<void> _leave() async {
    if (saving || leaving) return;
    leaving = true;
    try {
      final discard = await confirmAction(
        context,
        title: 'Zahodit změny?',
        message: 'Úpravy tohoto tréninku ještě nejsou uložené.',
        cancel: 'Pokračovat v úpravách',
        confirm: 'Zahodit změny',
        destructive: true,
      );
      if (!mounted || !discard) return;
      _exit();
    } finally {
      leaving = false;
    }
  }

  /// Zavře stránku až po překreslení, kdy už PopScope odchod pustí.
  void _exit() {
    // „Vrátit" by po odchodu už nemělo kam vrátit.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    draft
      ..name = name.text
      ..note = note.text;
    String? error;
    try {
      error = await widget.state.updateWorkout(draft);
    } catch (_) {
      error = 'Změny se nepodařilo uložit. Zkus to znovu.';
    } finally {
      if (mounted) setState(() => saving = false);
    }
    if (!mounted) return;
    if (error != null) {
      showToast(context, error);
      return;
    }
    _exit();
  }

  void _removeExercise(WorkoutExercise entry) {
    final index = draft.exercises.indexOf(entry);
    if (index < 0) return;
    setState(() => draft.exercises.removeAt(index));
    showUndo(
      context,
      'Cvik ${widget.state.exercise(entry.exerciseId).name} odebrán.',
      () {
        if (!mounted || draft.exercises.contains(entry)) return;
        setState(
          () => draft.exercises.insert(
            index.clamp(0, draft.exercises.length),
            entry,
          ),
        );
      },
    );
  }

  void _removeSet(WorkoutExercise entry, SetEntry set) {
    final index = entry.sets.indexOf(set);
    if (index < 0) return;
    setState(() => entry.sets.removeAt(index));
    showUndo(context, 'Série smazána.', () {
      if (!mounted || entry.sets.contains(set)) return;
      setState(() => entry.sets.insert(index.clamp(0, entry.sets.length), set));
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: allowExit || (!dirty && !saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upravit trénink'),
          actions: [
            TextButton(
              onPressed: saving || !dirty ? null : _save,
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Uložit',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(width: Space.xs),
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
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Název'),
            ),
            const SizedBox(height: Space.s),
            TextField(
              controller: note,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Poznámka'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xs, Space.s, 0, 0),
              child: Text(
                formatDateTime(draft.date),
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
            if (draft.exercises.isEmpty)
              const EmptyState(
                icon: Icons.fitness_center_rounded,
                title: 'Žádný cvik',
                message: 'Po uložení zůstane jen název a poznámka.',
              ),
            for (final entry in draft.exercises)
              Padding(
                key: ObjectKey(entry),
                padding: const EdgeInsets.only(top: Space.m),
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(
                    Space.l,
                    Space.xs,
                    Space.xs,
                    Space.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.state.exercise(entry.exerciseId).name,
                              style: text.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Odebrat cvik',
                            onPressed: () => _removeExercise(entry),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: p.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      if (entry.sets.isNotEmpty) const _SetHeader(),
                      for (final (i, set) in entry.sets.indexed)
                        _EditSetRow(
                          key: ObjectKey(set),
                          set: set,
                          label: set.warmup
                              ? 'R'
                              : '${entry.sets.take(i).where((s) => !s.warmup).length + 1}',
                          onChanged: _changed,
                          onWarmup: (v) => setState(() => set.warmup = v),
                          onRemove: () => _removeSet(entry, set),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(
                          () => entry.sets.add(
                            (entry.sets.lastOrNull?.copy() ?? SetEntry())
                              ..warmup = false
                              ..done = true,
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Série'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditSetRow extends StatefulWidget {
  final SetEntry set;
  final String label;
  final ValueChanged<bool> onWarmup;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _EditSetRow({
    super.key,
    required this.set,
    required this.label,
    required this.onWarmup,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_EditSetRow> createState() => _EditSetRowState();
}

class _EditSetRowState extends State<_EditSetRow> {
  late final weight = TextEditingController(
    text: widget.set.weight == 0 ? '' : formatKg(widget.set.weight),
  );
  late final reps = TextEditingController(
    text: widget.set.reps == 0 ? '' : '${widget.set.reps}',
  );

  String get _name => widget.set.warmup ? 'Rozcvička' : 'Série ${widget.label}';

  @override
  void dispose() {
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController c,
    String hint,
    String label, {
    bool decimal = false,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Semantics(
        label: label,
        child: TextField(
          controller: c,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontFeatures: tabular),
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
            ),
          ],
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.s,
              vertical: 12,
            ),
          ),
          onChanged: (_) {
            widget.set
              ..weight = parseNum(weight.text) ?? 0
              ..reps = int.tryParse(reps.text) ?? 0;
            widget.onChanged();
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final warmup = widget.set.warmup;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: minTap,
            height: minTap,
            child: PopupMenuButton<String>(
              tooltip: '$_name, změnit typ',
              padding: EdgeInsets.zero,
              onSelected: (v) => switch (v) {
                'delete' => widget.onRemove(),
                _ => widget.onWarmup(v == 'warmup'),
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'working',
                  checked: !warmup,
                  child: const Text('Pracovní série'),
                ),
                CheckedPopupMenuItem(
                  value: 'warmup',
                  checked: warmup,
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
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: warmup ? p.accent.withValues(alpha: 0.16) : p.fill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: text.titleSmall?.copyWith(
                      color: warmup ? p.accent : p.label,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _field(weight, 'kg', 'Kilogramy, $_name', decimal: true),
          _field(reps, 'opak.', 'Opakování, $_name'),
          IconButton(
            tooltip: 'Smazat sérii',
            onPressed: widget.onRemove,
            icon: Icon(Icons.close_rounded, color: p.tertiaryLabel),
          ),
        ],
      ),
    );
  }
}

/// Popisky sloupců nad sériemi jednoho cviku.
class _SetHeader extends StatelessWidget {
  const _SetHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: context.palette.secondaryLabel);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            SizedBox(
              width: minTap,
              child: Text('Série', style: style, textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text('kg', style: style, textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text('opak.', style: style, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/parse.dart';
import '../../domain/models.dart';
import '../widgets/set_kind.dart';
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
  final _invalidSets = <SetEntry>{};
  bool saving = false;
  bool allowExit = false;
  bool leaving = false;

  bool get dirty {
    final current = draft.copy()
      ..name = name.text
      ..note = note.text;
    return _invalidSets.isNotEmpty ||
        jsonEncode(current.toJson()) != jsonEncode(widget.workout.toJson());
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
        title: tr('Zahodit změny?', 'Discard changes?'),
        message: tr(
          'Úpravy tohoto tréninku ještě nejsou uložené.',
          'Changes to this workout have not been saved.',
        ),
        cancel: tr('Pokračovat v úpravách', 'Keep editing'),
        confirm: tr('Zahodit změny', 'Discard changes'),
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
    if (saving || _invalidSets.isNotEmpty) return;
    setState(() => saving = true);
    draft
      ..name = name.text
      ..note = note.text;
    String? error;
    try {
      error = await widget.state.updateWorkout(draft);
    } catch (_) {
      error = tr(
        'Změny se nepodařilo uložit. Zkus to znovu.',
        'Could not save changes. Try again.',
      );
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
    setState(() {
      _invalidSets.removeAll(entry.sets);
      draft.exercises.removeAt(index);
    });
    showUndo(
      context,
      tr(
        'Cvik ${widget.state.exercise(entry.exerciseId).name} odebrán.',
        'Exercise ${widget.state.exercise(entry.exerciseId).name} removed.',
      ),
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
    setState(() {
      _invalidSets.remove(set);
      entry.sets.removeAt(index);
    });
    showUndo(context, tr('Série smazána.', 'Set deleted.'), () {
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
          title: Text(tr('Upravit trénink', 'Edit workout')),
          actions: [
            TextButton(
              onPressed: saving || !dirty || _invalidSets.isNotEmpty
                  ? null
                  : _save,
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      tr('Uložit', 'Save'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
              decoration: InputDecoration(labelText: tr('Název', 'Name')),
            ),
            const SizedBox(height: Space.s),
            TextField(
              controller: note,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: tr('Poznámka', 'Note')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xs, Space.s, 0, 0),
              child: Text(
                formatDateTime(draft.date),
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
            if (draft.exercises.isEmpty)
              EmptyState(
                icon: Icons.fitness_center_rounded,
                title: tr('Žádný cvik', 'No exercises'),
                message: tr(
                  'Po uložení zůstane jen název a poznámka.',
                  'After saving, only the name and note will remain.',
                ),
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
                            tooltip: tr('Odebrat cvik', 'Remove exercise'),
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
                          label: setBadge(
                            set,
                            entry.sets.take(i).where((s) => !s.warmup).length +
                                1,
                          ),
                          onChanged: (valid) => setState(() {
                            valid
                                ? _invalidSets.remove(set)
                                : _invalidSets.add(set);
                          }),
                          onType: (v) => setState(() {
                            set
                              ..warmup = v == 'warmup'
                              ..kind =
                                  SetKind.values
                                      .where((k) => k.name == v)
                                      .firstOrNull ??
                                  SetKind.normal;
                          }),
                          onRemove: () => _removeSet(entry, set),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(
                          () => entry.sets.add(
                            (entry.sets.lastOrNull?.copy() ?? SetEntry())
                              ..warmup = false
                              ..kind = SetKind.normal
                              ..extra.remove('rpe')
                              ..done = true,
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(tr('Série', 'Set')),
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
  final ValueChanged<String> onType;
  final VoidCallback onRemove;
  final ValueChanged<bool> onChanged;
  const _EditSetRow({
    super.key,
    required this.set,
    required this.label,
    required this.onType,
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

  String get _name => setName(widget.set, widget.label);

  @override
  void dispose() {
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  String? _problem(String raw, {required bool decimal}) {
    if (raw.trim().isEmpty) return null;
    if (decimal) {
      final v = parseNum(raw);
      return v != null && v >= 0
          ? null
          : tr('Zadej váhu od 0 kg.', 'Enter a weight of 0 kg or more.');
    }
    final v = int.tryParse(raw.trim());
    return v != null && v >= 0 && v <= 999
        ? null
        : tr(
            'Zadej celé opakování od 0 do 999.',
            'Enter whole reps between 0 and 999.',
          );
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
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            errorText: _problem(c.text, decimal: decimal),
            errorMaxLines: 3,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.s,
              vertical: 12,
            ),
          ),
          onChanged: (_) {
            final valid =
                _problem(weight.text, decimal: true) == null &&
                _problem(reps.text, decimal: false) == null;
            if (valid) {
              widget.set
                ..weight = parseNum(weight.text) ?? 0
                ..reps = int.tryParse(reps.text.trim()) ?? 0;
            }
            setState(() {});
            widget.onChanged(valid);
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final warmup = widget.set.warmup || widget.set.kind != SetKind.normal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: minTap,
            height: minTap,
            child: PopupMenuButton<String>(
              tooltip: tr('$_name, změnit typ', '$_name, change type'),
              padding: EdgeInsets.zero,
              onSelected: (v) => switch (v) {
                'delete' => widget.onRemove(),
                _ => widget.onType(v),
              },
              itemBuilder: (_) => [
                ...setTypeItems(widget.set),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    tr('Smazat sérii', 'Delete set'),
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
          _field(
            weight,
            'kg',
            tr('Kilogramy, $_name', 'Kilograms, $_name'),
            decimal: true,
          ),
          _field(
            reps,
            tr('opak.', 'reps'),
            tr('Opakování, $_name', 'Reps, $_name'),
          ),
          IconButton(
            tooltip: tr('Smazat sérii', 'Delete set'),
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
              child: Text(
                tr('Série', 'Set'),
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text('kg', style: style, textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text(
                tr('opak.', 'reps'),
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

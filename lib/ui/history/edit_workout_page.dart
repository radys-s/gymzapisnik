import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';

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

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Upravit trénink'),
      actions: [
        TextButton(
          onPressed: saving ? null : _save,
          child: const Text('Uložit'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Název'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: note,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(labelText: 'Poznámka'),
        ),
        for (final entry in draft.exercises)
          Card(
            key: ObjectKey(entry),
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.state.exercise(entry.exerciseId).name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Odebrat cvik',
                        onPressed: () =>
                            setState(() => draft.exercises.remove(entry)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  for (final set in entry.sets)
                    _EditSetRow(
                      key: ObjectKey(set),
                      set: set,
                      onWarmup: () => setState(() => set.warmup = !set.warmup),
                      onRemove: () => setState(() => entry.sets.remove(set)),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => entry.sets.add(
                        (entry.sets.lastOrNull?.copy() ?? SetEntry())
                          ..warmup = false
                          ..done = true,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Série'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _EditSetRow extends StatefulWidget {
  final SetEntry set;
  final VoidCallback onWarmup;
  final VoidCallback onRemove;
  const _EditSetRow({
    super.key,
    required this.set,
    required this.onWarmup,
    required this.onRemove,
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

  @override
  void dispose() {
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool decimal = false,
  }) => Expanded(
    child: Padding(
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
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (_) {
          widget.set
            ..weight = parseNum(weight.text) ?? 0
            ..reps = int.tryParse(reps.text) ?? 0;
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        FilterChip(
          label: const Text('R'),
          tooltip: 'Rozcvička',
          selected: widget.set.warmup,
          onSelected: (_) => widget.onWarmup(),
        ),
        _field(weight, 'kg', decimal: true),
        _field(reps, 'opak.'),
        IconButton(
          tooltip: 'Smazat sérii',
          onPressed: widget.onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

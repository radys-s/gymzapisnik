import 'package:flutter/material.dart';

import '../../core/text.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Výběr cviků. Vrací seznam ID vybraných cviků přes `Navigator.pop`.
/// Při [multiple] jde vybrat víc cviků a přidat je najednou,
/// jinak klepnutí rovnou vrátí jeden cvik (náhrada).
class ExercisePickerPage extends StatefulWidget {
  final AppState state;
  final bool multiple;
  const ExercisePickerPage(this.state, {super.key, this.multiple = true});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  String query = '';

  /// Vybrané cviky v pořadí klepnutí (v tomto pořadí se přidají).
  final selected = <String>[];

  /// Naposledy cvičené cviky (max 8), od nejnovějšího.
  late final List<Exercise> recent = () {
    final ids = <String>[];
    for (final w in widget.state.workouts) {
      for (final e in w.exercises) {
        if (!ids.contains(e.exerciseId)) ids.add(e.exerciseId);
      }
      if (ids.length >= 8) break;
    }
    return [for (final id in ids.take(8)) widget.state.exercise(id)];
  }();

  void _tap(Exercise e) {
    if (!widget.multiple) {
      Navigator.pop(context, [e.id]);
      return;
    }
    setState(() {
      if (!selected.remove(e.id)) selected.add(e.id);
    });
  }

  Future<void> _createCustom() async {
    final created = await showDialog<Exercise>(
      context: context,
      builder: (_) => _CustomExerciseDialog(widget.state, initialName: query),
    );
    if (created == null || !mounted) return;
    if (!widget.multiple) {
      Navigator.pop(context, [created.id]);
      return;
    }
    setState(() => selected.add(created.id));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final folded = fold(query.trim());
    final matches = widget.state.allExercises
        .where((e) => folded.isEmpty || fold(e.name).contains(folded))
        .toList();
    final sections = <String, List<Exercise>>{};
    if (folded.isEmpty && recent.isNotEmpty) sections['Nedávné'] = recent;
    for (final group in muscleGroups) {
      final list = matches.where((e) => e.muscle == group).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (list.isNotEmpty) sections[group] = list;
    }
    final count = selected.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.multiple ? 'Přidat cviky' : 'Nahradit cvik'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          // Bez automatického fokusu: klávesnice nezakryje nedávné cviky.
          TextField(
            decoration: const InputDecoration(
              hintText: 'Hledat cvik',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: Space.xl),
          GroupedSection(
            children: [
              GroupedRow(
                leading: Icon(Icons.add_rounded, color: p.accent),
                title: 'Vlastní cvik',
                chevron: false,
                onTap: _createCustom,
              ),
            ],
          ),
          if (sections.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nic nenalezeno',
              message: 'Zkus jiný název, nebo přidej vlastní cvik.',
            ),
          for (final section in sections.entries)
            GroupedSection(
              header: section.key,
              children: [
                for (final e in section.value)
                  _ExerciseRow(
                    exercise: e,
                    selected: selected.contains(e.id),
                    multiple: widget.multiple,
                    onTap: () => _tap(e),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: !widget.multiple || count == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.page,
                  Space.s,
                  Space.page,
                  Space.s,
                ),
                child: PrimaryButton(
                  count == 1 ? 'Přidat cvik' : 'Přidat cviky ($count)',
                  onPressed: () => Navigator.pop(context, [...selected]),
                ),
              ),
            ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final bool selected;
  final bool multiple;
  final VoidCallback onTap;
  const _ExerciseRow({
    required this.exercise,
    required this.selected,
    required this.multiple,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      button: true,
      selected: multiple ? selected : null,
      child: GroupedRow(
        title: exercise.name,
        subtitle: exercise.type == ExerciseType.bodyweight
            ? 'vlastní váha'
            : null,
        chevron: false,
        trailing: !multiple
            ? null
            : Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? p.accent : p.tertiaryLabel,
              ),
        onTap: onTap,
      ),
    );
  }
}

class _CustomExerciseDialog extends StatefulWidget {
  final AppState state;
  final String initialName;
  const _CustomExerciseDialog(this.state, {required this.initialName});

  @override
  State<_CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<_CustomExerciseDialog> {
  late final name = TextEditingController(text: widget.initialName.trim());
  String muscle = muscleGroups.first;
  ExerciseType type = ExerciseType.weighted;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      final created = await widget.state.addCustomExercise(
        name: name.text,
        muscle: muscle,
        type: type,
      );
      if (mounted) Navigator.pop(context, created);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Cvik se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Vlastní cvik'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Název'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Space.m),
        DropdownButtonFormField<String>(
          initialValue: muscle,
          decoration: const InputDecoration(labelText: 'Partie'),
          items: [
            for (final g in muscleGroups)
              DropdownMenuItem(value: g, child: Text(g)),
          ],
          onChanged: (v) => setState(() => muscle = v ?? muscle),
        ),
        const SizedBox(height: Space.m),
        SegmentedButton<ExerciseType>(
          segments: const [
            ButtonSegment(value: ExerciseType.weighted, label: Text('S váhou')),
            ButtonSegment(
              value: ExerciseType.bodyweight,
              label: Text('Vlastní váha'),
            ),
          ],
          selected: {type},
          onSelectionChanged: (v) => setState(() => type = v.first),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zpět'),
      ),
      TextButton(
        onPressed: saving || name.text.trim().isEmpty ? null : _save,
        child: const Text('Uložit'),
      ),
    ],
  );
}

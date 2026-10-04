import 'package:flutter/material.dart';

import '../../core/text.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';

/// Výběr cviku. Vrací ID vybraného cviku přes `Navigator.pop`.
class ExercisePickerPage extends StatefulWidget {
  final AppState state;
  const ExercisePickerPage(this.state, {super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  String query = '';

  /// Naposledy cvičené cviky (max 8), od nejnovějšího.
  List<Exercise> get recent {
    final ids = <String>[];
    for (final w in widget.state.workouts) {
      for (final e in w.exercises) {
        if (!ids.contains(e.exerciseId)) ids.add(e.exerciseId);
      }
      if (ids.length >= 8) break;
    }
    return [for (final id in ids.take(8)) widget.state.exercise(id)];
  }

  Future<void> _createCustom() async {
    final created = await showDialog<Exercise>(
      context: context,
      builder: (_) => _CustomExerciseDialog(widget.state, initialName: query),
    );
    if (created != null && mounted) Navigator.pop(context, created.id);
  }

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Hledat cvik',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => query = v),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Vlastní cvik'),
            onTap: _createCustom,
          ),
          if (sections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nic nenalezeno. Přidej vlastní cvik.'),
            ),
          for (final section in sections.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                section.key,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final e in section.value)
              ListTile(
                title: Text(e.name),
                subtitle: e.type == ExerciseType.bodyweight
                    ? const Text('vlastní váha')
                    : null,
                onTap: () => Navigator.pop(context, e.id),
              ),
          ],
        ],
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
    final created = await widget.state.addCustomExercise(
      name: name.text,
      muscle: muscle,
      type: type,
    );
    if (mounted) Navigator.pop(context, created);
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
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: muscle,
          decoration: const InputDecoration(labelText: 'Partie'),
          items: [
            for (final g in muscleGroups)
              DropdownMenuItem(value: g, child: Text(g)),
          ],
          onChanged: (v) => setState(() => muscle = v ?? muscle),
        ),
        const SizedBox(height: 12),
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

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/text.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/exercise_media.dart';
import '../widgets/labels.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import 'exercise_detail_page.dart';

/// Exercise library with fast search, muscle/equipment filters, and recent records.
class ExercisesPage extends StatefulWidget {
  final AppState state;
  const ExercisesPage(this.state, {super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String query = '';
  String? muscle;
  Equipment? equipment;
  bool gymOnly = false;

  void _open(String id) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ExerciseDetailPage(widget.state, id)),
  );

  bool _matches(Exercise e, String folded) {
    if (folded.isEmpty) return true;
    bool has(String s) => fold(s).contains(folded);
    if (has(e.name) || has(e.nameCs) || has(e.muscle)) return true;
    if (has(e.equipment.label)) return true;
    return e.aliases.any(has);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state.on.resting,
    builder: (context, _) {
      final state = widget.state;
      final folded = fold(query.trim());
      final trained = <String, int>{};
      for (final w in state.workouts) {
        for (final e in w.exercises) {
          if (e.countedSets.isNotEmpty) {
            trained[e.exerciseId] = (trained[e.exerciseId] ?? 0) + 1;
          }
        }
      }
      final all = state.allExercises;
      final filtered = [
        for (final e in all)
          if ((muscle == null || e.muscle == muscle) &&
              (equipment == null || e.equipment == equipment) &&
              (!gymOnly || state.gymHas(e.id)) &&
              _matches(e, folded))
            e,
      ];
      final recent =
          [
            for (final e in all)
              if (state.recordsOf(e.id).isNotEmpty) e,
          ]..sort((a, b) {
            final ad = state
                .recordsOf(a.id)
                .values
                .map((r) => r.date)
                .fold<DateTime?>(
                  null,
                  (m, d) => m == null || d.isAfter(m) ? d : m,
                );
            final bd = state
                .recordsOf(b.id)
                .values
                .map((r) => r.date)
                .fold<DateTime?>(
                  null,
                  (m, d) => m == null || d.isAfter(m) ? d : m,
                );
            return (bd ?? DateTime(0)).compareTo(ad ?? DateTime(0));
          });

      Widget chip<T>({
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
        return Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: FilterChip(
            selected: selected,
            label: Text(label),
            onSelected: (_) => onTap(),
            showCheckmark: false,
          ),
        );
      }

      return LargeTitlePage(
        title: tr('Cviky', 'Exercises'),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: tr(
                'Hledat cvik, sval, vybavení, česky/EN…',
                'Search exercise, muscle, equipment, Czech/EN…',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: Space.s),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  label: tr('Vše', 'All'),
                  selected: muscle == null,
                  onTap: () => setState(() => muscle = null),
                ),
                for (final m in muscleGroups)
                  chip(
                    label: muscleLabel(m),
                    selected: muscle == m,
                    onTap: () =>
                        setState(() => muscle = muscle == m ? null : m),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  label: tr('Vše vybavení', 'All equipment'),
                  selected: equipment == null,
                  onTap: () => setState(() => equipment = null),
                ),
                for (final e in Equipment.values)
                  chip(
                    label: e.label,
                    selected: equipment == e,
                    onTap: () =>
                        setState(() => equipment = equipment == e ? null : e),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              selected: gymOnly,
              showCheckmark: false,
              label: Text(tr('Jen moje posilovna', 'My gym only')),
              onSelected: (v) => setState(() => gymOnly = v),
            ),
          ),
          const SizedBox(height: Space.s),
          if (folded.isEmpty &&
              muscle == null &&
              equipment == null &&
              !gymOnly &&
              recent.isNotEmpty) ...[
            SectionHeader(tr('Nedávné rekordy', 'Recent records')),
            GroupedSection(
              children: [
                for (final e in recent.take(6))
                  _ExerciseRow(
                    e: e,
                    trained: trained[e.id] ?? 0,
                    onTap: () => _open(e.id),
                  ),
              ],
            ),
          ],
          SectionHeader(
            folded.isEmpty && muscle == null && equipment == null && !gymOnly
                ? tr('Knihovna cviků', 'Exercise library')
                : tr(
                    'Výsledky (${filtered.length})',
                    'Results (${filtered.length})',
                  ),
          ),
          if (filtered.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: tr('Nic nenalezeno', 'Nothing found'),
              message: gymOnly
                  ? tr(
                      'V této posilovně nic neodpovídá filtru. Zkus vypnout "Jen moje posilovna" nebo změnit hledání.',
                      'Nothing in this gym matches the filter. Try turning off "My gym only" or changing the search.',
                    )
                  : tr(
                      'Zkus jiný název, sval nebo vybavení. Hledání rozumí anglickým i českým názvům.',
                      'Try a different name, muscle or equipment. Search understands both English and Czech names.',
                    ),
            )
          else
            GroupedSection(
              children: [
                for (final e in filtered)
                  _ExerciseRow(
                    e: e,
                    trained: trained[e.id] ?? 0,
                    onTap: () => _open(e.id),
                  ),
              ],
            ),
        ],
      );
    },
  );
}

class _ExerciseRow extends StatelessWidget {
  final Exercise e;
  final int trained;
  final VoidCallback onTap;
  const _ExerciseRow({
    required this.e,
    required this.trained,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subtitle = [
      if (e.nameCs.isNotEmpty && fold(e.nameCs) != fold(e.name)) e.nameCs,
      muscleLabel(e.muscle),
      e.equipment.label,
      if (trained > 0) tr('$trained× v historii', '$trained× in history'),
    ].join(' · ');
    return GroupedRow(
      leading: ExerciseThumb(e.id),
      title: e.name,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: p.tertiaryLabel,
        size: 20,
      ),
    );
  }
}

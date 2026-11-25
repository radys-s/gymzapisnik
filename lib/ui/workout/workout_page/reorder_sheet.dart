part of '../workout_page.dart';

// Pořadí cviků a rozdíl proti minule.

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
              child: Text(
                tr('Seřadit cviky', 'Reorder exercises'),
                style: text.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                0,
                Space.page,
                Space.m,
              ),
              child: Text(
                tr(
                  'Podrž úchyt vpravo a přetáhni cvik na nové místo.',
                  'Hold the handle on the right and drag the exercise to a new spot.',
                ),
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
                        SnackBar(
                          content: Text(
                            tr(
                              'Pořadí se nepodařilo uložit. Zkus to znovu.',
                              'Could not save the order. Try again.',
                            ),
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
                  final working = entry.sets.where((s) => !s.warmup).length;
                  return ListTile(
                    key: ObjectKey(entry),
                    leading: ExerciseThumb(exercise.id, size: 36),
                    title: Text(exercise.name),
                    subtitle: Text(
                      done.isEmpty
                          ? tr(
                              'Zatím bez potvrzené série',
                              'No confirmed sets yet',
                            )
                          : tr(
                              'Hotovo ${done.length} z $working',
                              'Done ${done.length} of $working',
                            ),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: Semantics(
                        label: tr(
                          'Přetáhnout ${exercise.name}',
                          'Drag ${exercise.name}',
                        ),
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

/// Řádek „proti minule“: nejtěžší série a objem dnes vs. minulý trénink
/// tohoto cviku. Šipka ukáže, jestli se dnes jde nahoru.
class _LastDeltaRow extends StatelessWidget {
  final LastDelta d;
  const _LastDeltaRow(this.d);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final last = d.lastTop;
    final now = d.nowTop;
    final lastLabel = '${formatKg(last.weight)}×${last.reps}';
    final String headline;
    Color? tone;
    if (now == null) {
      headline = tr(
        'Minule nejvíc $lastLabel · objem ${_kg(d.lastVolume)}',
        'Last best $lastLabel · volume ${_kg(d.lastVolume)}',
      );
    } else {
      final diff = now.weight - last.weight;
      final repsDiff = now.reps - last.reps;
      final up = diff > 0 || (diff == 0 && repsDiff > 0);
      // Pokles hlásí až po tolika sériích jako minule: lehčí první
      // série na začátku tréninku není zhoršení.
      final down =
          (diff < 0 || (diff == 0 && repsDiff < 0)) && d.nowSets >= d.lastSets;
      final same = tr('stejně', 'same');
      final change = diff != 0
          ? '${diff > 0 ? '+' : '−'}${formatKg(diff.abs())} kg'
          : repsDiff != 0
          ? '${repsDiff > 0 ? '+' : '−'}${repsDiff.abs()} ${tr('opak.', 'reps')}'
          : same;
      tone = up
          ? p.positive
          : down
          ? p.secondaryLabel
          : null;
      final sign = up
          ? '▲ $change'
          : down
          ? '▼ $change'
          : change == same
          ? '= $same'
          : tr('zatím $change', '$change so far');
      headline = tr(
        '$sign proti minule ($lastLabel) · '
            'objem ${_kg(d.nowVolume)} z ${_kg(d.lastVolume)}',
        '$sign vs last ($lastLabel) · '
            'volume ${_kg(d.nowVolume)} of ${_kg(d.lastVolume)}',
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.s),
      child: Text(
        headline,
        style: text.bodySmall?.copyWith(
          color: tone ?? p.secondaryLabel,
          fontFeatures: tabular,
          fontWeight: tone == null ? null : FontWeight.w600,
        ),
      ),
    );
  }

  static String _kg(double v) => '${formatKg(v)} kg';
}

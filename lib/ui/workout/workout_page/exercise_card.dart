part of '../workout_page.dart';

// Karta cviku se sériemi.

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

  /// Místo v supersérii, `null` = samostatný cvik.
  final SupersetSlot? superset;
  final ValueChanged<String> onMenu;
  final ValueChanged<SetEntry> onRemoveSet;
  final ValueChanged<String> onError;

  const _ExerciseCard({
    super.key,
    required this.state,
    required this.entry,
    required this.canMoveUp,
    required this.canMoveDown,
    this.superset,
    required this.onMenu,
    required this.onRemoveSet,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final exercise = state.exercise(entry.exerciseId);
    // Minulé série se hledají v celé historii: jednou na kartu.
    final last = state.lastSetsOf(entry.exerciseId);
    final previous = previousSets(entry.sets, last);
    final bodyweight = exercise.type == ExerciseType.bodyweight;
    final pinned = state.profile.exerciseNote(exercise.id);
    final slot = superset;
    final linked = slot != null && !slot.isLast;
    var workingIndex = 0;
    return _SupersetFrame(
      slot: slot,
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
            if (slot != null) _SupersetLabel(slot),
            Row(
              children: [
                Expanded(
                  // Fotka a název otevřou kartu cviku: technika, svaly.
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      context.palette.controlRadius,
                    ),
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
                Semantics(
                  container: true,
                  button: true,
                  label: 'Vyměnit cvik',
                  onTap: () => onMenu('replace'),
                  excludeSemantics: true,
                  child: IconButton(
                    onPressed: () => onMenu('replace'),
                    icon: Icon(Icons.swap_horiz_rounded, color: p.accent),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Možnosti cviku',
                  icon: Icon(Icons.more_horiz_rounded, color: p.secondaryLabel),
                  onSelected: onMenu,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'note', child: Text('Poznámka')),
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(
                        pinned == null
                            ? 'Připnout poznámku'
                            : 'Upravit připnutou poznámku',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rest',
                      child: Text(
                        'Pauza: ${restLabel(state.restFor(exercise.id))}',
                      ),
                    ),
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
                    if (canMoveDown && !linked)
                      const PopupMenuItem(
                        value: 'superset',
                        child: Text('Supersérie s dalším cvikem'),
                      ),
                    if (slot != null)
                      const PopupMenuItem(
                        value: 'unsuperset',
                        child: Text('Zrušit supersérii'),
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
            if (pinned != null)
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
                      Icons.push_pin_rounded,
                      size: 16,
                      color: p.secondaryLabel,
                      semanticLabel: 'Připnutá poznámka',
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(pinned, style: text.bodySmall)),
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
            if (!bodyweight)
              if (compareToLast(entry.sets, last) case final d?)
                _LastDeltaRow(d),
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
                label: setBadge(entry.sets[i], ++workingIndex),
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

/// Barva supersérie podle písmene skupiny.
Color _supersetColor(SupersetSlot slot) =>
    AppPalette.superset[slot.group % AppPalette.superset.length];

/// Odsazení karty a pruh vlevo, který spojí cviky supersérie.
class _SupersetFrame extends StatelessWidget {
  final SupersetSlot? slot;
  final Widget child;

  const _SupersetFrame({required this.slot, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = slot;
    if (s == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: child,
      );
    }
    return Container(
      // Cviky jedné skupiny drží u sebe, za poslední je běžná mezera.
      margin: EdgeInsets.only(bottom: s.isLast ? Space.m : Space.xs),
      padding: const EdgeInsets.only(left: Space.s),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: _supersetColor(s), width: 3)),
      ),
      child: child,
    );
  }
}

/// „Supersérie A · 1/2“ nad názvem cviku.
class _SupersetLabel extends StatelessWidget {
  final SupersetSlot slot;
  const _SupersetLabel(this.slot);

  @override
  Widget build(BuildContext context) {
    final color = _supersetColor(slot);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, 0, 0),
      child: Semantics(
        container: true,
        label:
            'Supersérie ${slot.letter}, cvik ${slot.position + 1} '
            'z ${slot.size}, střídej bez pauzy',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(Icons.link_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              'Supersérie ${slot.letter} · ${slot.position + 1}/${slot.size}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

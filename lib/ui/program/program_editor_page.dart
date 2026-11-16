import 'dart:convert';

import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/routine_audit.dart';
import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/motion.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../workout/alternatives_page.dart';
import '../workout/exercise_picker.dart';
import '../widgets/muscle_tile_grid.dart';
import 'audit_panel.dart';
import 'program_widgets.dart';

/// Rozpracovaný den v editoru (název v poli, cviky v seznamu).
class _DayDraft {
  final Key key = UniqueKey();
  final TextEditingController name;
  List<PlannedExercise> exercises;
  _DayDraft(String name, this.exercises)
    : name = TextEditingController(text: name);

  SplitDay toDay() => SplitDay(name.text.trim(), exercises);
}

/// Předvolby série × opakování.
const _presets = [
  ('Síla', 4, 5, 8),
  ('Svaly', 3, 8, 12),
  ('Vytrvalost', 3, 12, 15),
];

/// Editor vlastního programu: název, dny, cviky, série × opakování.
/// S [initial] hotovou šablonou vznikne kopie; s vlastním programem úprava.
/// Po uložení vrací ID uloženého programu.
class ProgramEditorPage extends StatefulWidget {
  final AppState state;
  final SplitTemplate? initial;
  const ProgramEditorPage(this.state, {super.key, this.initial});

  @override
  State<ProgramEditorPage> createState() => _ProgramEditorPageState();
}

class _ProgramEditorPageState extends State<ProgramEditorPage> {
  AppState get state => widget.state;
  late final String? _id;
  late final TextEditingController _name;
  late final List<_DayDraft> _days;
  late final String _saved;
  bool _busy = false;
  bool _done = false;

  /// Odebrané dny (kvůli Vrátit); ovladače se uvolní až s editorem.
  final List<_DayDraft> _removed = [];

  /// Po uložení začne program platit: nový program, kopie aktuálního
  /// programu, nebo když zatím žádný program není.
  late final bool _activate;

  bool get _isNew => _id == null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = initial != null && initial.custom ? initial.id : null;
    _name = TextEditingController(
      text: initial == null
          ? ''
          : initial.custom
          ? initial.name
          : '${initial.name} (vlastní)',
    )..addListener(_changed);
    _days = [
      for (final d in initial?.days ?? const <SplitDay>[])
        _DayDraft(d.name, [...d.exercises]),
    ];
    for (final d in _days) {
      d.name.addListener(_changed);
    }
    _saved = _snapshot();
    _activate =
        _isNew &&
        (initial == null ||
            state.split == null ||
            state.split!.id == initial.id);
  }

  @override
  void dispose() {
    _name.dispose();
    for (final d in [..._days, ..._removed]) {
      d.name.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  SplitTemplate _draft() => SplitTemplate(
    id: _id ?? '',
    name: _name.text.trim(),
    description: '',
    perWeek: _days.length.clamp(1, 7),
    days: [for (final d in _days) d.toDay()],
    custom: true,
  );

  String _snapshot() => jsonEncode(_draft().toJson());

  bool get _dirty => !_done && _snapshot() != _saved;

  _DayDraft _addDraft(SplitDay day, {int? at}) {
    final draft = _DayDraft(day.name, [...day.exercises]);
    draft.name.addListener(_changed);
    setState(() => _days.insert(at ?? _days.length, draft));
    return draft;
  }

  void _removeDay(_DayDraft day) {
    final at = _days.indexOf(day);
    final before = at > 0 ? _days[at - 1] : null;
    setState(() => _days.removeAt(at));
    _removed.add(day);
    showUndo(context, 'Den ${day.name.text.trim()} odebrán.', () {
      if (!mounted || _days.contains(day)) return;
      // Vrátí se za původního souseda, i když se mezitím pořadí změnilo.
      final after = before == null ? -1 : _days.indexOf(before);
      setState(() {
        _removed.remove(day);
        _days.insert(before == null || after < 0 ? 0 : after + 1, day);
      });
    });
  }

  void _moveDay(_DayDraft day, int by) {
    final at = _days.indexOf(day);
    final to = at + by;
    if (to < 0 || to >= _days.length) return;
    setState(() {
      _days.removeAt(at);
      _days.insert(to, day);
    });
  }

  /// „Push 2“, zkrácené tak, aby se vešlo do limitu názvu.
  static String _copyName(String name) {
    final base = name.length > maxNameLength - 2
        ? name.substring(0, maxNameLength - 2).trimRight()
        : name;
    return '$base 2'.trim();
  }

  Future<void> _addDay() async {
    if (_days.length >= maxProgramDays) {
      showToast(context, 'Program může mít nejvýš $maxProgramDays dní.');
      return;
    }
    final day = await showModalBottomSheet<SplitDay>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddDaySheet(state: state, number: _days.length + 1),
    );
    if (day == null || !mounted) return;
    final draft = _addDraft(day);
    // Den bez návrhu: rovnou seznam cviků, ať nezůstane prázdný.
    if (day.exercises.isEmpty) await _addExercises(draft);
  }

  Future<void> _addExercises(_DayDraft day) async {
    final ids = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => ExercisePickerPage(state)),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    final free = maxDayExercises - day.exercises.length;
    setState(
      () => day.exercises = [
        ...day.exercises,
        for (final id in ids.take(free)) PlannedExercise(id),
      ],
    );
    if (ids.length > free) {
      showToast(context, 'Den může mít nejvýš $maxDayExercises cviků.');
    }
  }

  Future<void> _editExercise(_DayDraft day, int index) async {
    void apply(PlannedExercise next) {
      if (index < day.exercises.length) {
        setState(() => day.exercises = [...day.exercises]..[index] = next);
      }
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExerciseSheet(
        name: state.exercise(day.exercises[index].exerciseId).name,
        initial: day.exercises[index],
        canUp: index > 0,
        canDown: index < day.exercises.length - 1,
        onChanged: apply,
      ),
    );
    if (!mounted || action == null) return;
    final list = [...day.exercises];
    switch (action) {
      case 'up' || 'down':
        final to = action == 'up' ? index - 1 : index + 1;
        list.insert(to, list.removeAt(index));
        setState(() => day.exercises = list);
      case 'remove':
        final removed = list.removeAt(index);
        setState(() => day.exercises = list);
        showUndo(
          context,
          '${state.exercise(removed.exerciseId).name} odebrán.',
          () {
            if (!mounted) return;
            setState(
              () =>
                  day.exercises = [...day.exercises]
                    ..insert(index.clamp(0, day.exercises.length), removed),
            );
          },
        );
      case 'replace':
        final id = await pickAlternative(
          context,
          state,
          day.exercises[index].exerciseId,
        );
        if (id == null || !mounted) return;
        if (index < day.exercises.length) {
          apply(day.exercises[index].copyWith(exerciseId: id));
        }
    }
  }

  /// Vloží navržený cvik z kontroly do dne, kam patří.
  void _addSuggested(AuditFinding f) {
    final id = f.exerciseId;
    if (id == null || _days.isEmpty) return;
    final day = _days[f.dayIndex.clamp(0, _days.length - 1)];
    if (day.exercises.length >= maxDayExercises) {
      showToast(context, 'Den může mít nejvýš $maxDayExercises cviků.');
      return;
    }
    setState(() => day.exercises = [...day.exercises, PlannedExercise(id)]);
    showToast(
      context,
      '${state.exercise(id).name} přidán do dne ${day.name.text.trim()}.',
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    final draft = _draft();
    final error = programError(draft);
    if (error != null) {
      showToast(context, error);
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await state.saveProgram(draft, activate: _activate);
      if (!mounted) return;
      setState(() => _done = true);
      showToast(
        context,
        _activate ? 'Program ${saved.name} je aktivní.' : 'Program uložen.',
      );
      Navigator.pop(context, saved.id);
    } on ArgumentError catch (e) {
      if (mounted) showToast(context, '${e.message}');
    } catch (_) {
      if (mounted) showToast(context, 'Program se nepodařilo uložit.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final ok = await confirmAction(
      context,
      title: 'Zahodit změny?',
      message: 'Neuložené úpravy programu se ztratí.',
      confirm: 'Zahodit',
      cancel: 'Pokračovat v úpravách',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _done = true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final exercises = _days.fold(0, (n, d) => n + d.exercises.length);
    final answers = state.planAnswers;
    final findings = exercises == 0
        ? const <AuditFinding>[]
        : auditRoutine([
            for (final d in _days) d.toDay(),
          ], allowed: answers?.allows);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: LargeTitlePage(
        title: _isNew ? 'Nový program' : 'Upravit program',
        bottom: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              Space.s,
              Space.page,
              Space.s,
            ),
            child: PrimaryButton(
              _activate
                  ? 'Uložit a používat'
                  : _isNew
                  ? 'Uložit kopii'
                  : 'Uložit změny',
              busy: _busy,
              onPressed: _save,
            ),
          ),
        ),
        children: [
          Panel(
            child: TextField(
              controller: _name,
              maxLength: maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Název programu',
                hintText: 'Třeba Ruce a ramena',
                counterText: '',
              ),
            ),
          ),
          if (exercises > 0)
            AuditPanel(state: state, findings: findings, onAdd: _addSuggested),
          SectionHeader(
            _days.isEmpty
                ? 'Dny'
                : 'Dny · ${_days.length} · $exercises '
                      '${exercises == 1 ? 'cvik' : (exercises >= 2 && exercises <= 4 ? 'cviky' : 'cviků')}',
          ),
          if (_days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.m),
              child: Panel(
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: p.accent),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Text(
                        'Přidej první den. Cviky ti navrhnu podle partií, '
                        'nebo si je vybereš sám ze seznamu.',
                        style: text.bodyMedium?.copyWith(
                          color: p.secondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < _days.length; i++)
            _DayCard(
              key: _days[i].key,
              state: state,
              index: i,
              count: _days.length,
              draft: _days[i],
              onMove: (by) => _moveDay(_days[i], by),
              onDuplicate: _days.length >= maxProgramDays
                  ? null
                  : () => _addDraft(
                      _days[i].toDay().copyWith(
                        name: _copyName(_days[i].name.text.trim()),
                      ),
                      at: i + 1,
                    ),
              onRemove: () => _removeDay(_days[i]),
              onAddExercises: () => _addExercises(_days[i]),
              onEditExercise: (e) => _editExercise(_days[i], e),
            ),
          SecondaryButton(
            'Přidat den',
            icon: Icons.add_rounded,
            onPressed: _days.length >= maxProgramDays ? null : _addDay,
          ),
          const SizedBox(height: Space.s),
          Text(
            'Dny jdou za sebou dokola: po posledním zase první. '
            'Kdy cvičíš, nastavíš ve Frekvenci.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

/// Karta dne: název, cviky, přidání cviků a menu.
class _DayCard extends StatelessWidget {
  final AppState state;
  final int index;
  final int count;
  final _DayDraft draft;
  final ValueChanged<int> onMove;
  final VoidCallback? onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onAddExercises;
  final ValueChanged<int> onEditExercise;

  const _DayCard({
    super.key,
    required this.state,
    required this.index,
    required this.count,
    required this.draft,
    required this.onMove,
    required this.onDuplicate,
    required this.onRemove,
    required this.onAddExercises,
    required this.onEditExercise,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final full = draft.exercises.length >= maxDayExercises;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.xs, Space.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Den ${index + 1}',
                  style: text.labelMedium?.copyWith(
                    color: p.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Možnosti dne ${index + 1}',
                  icon: Icon(Icons.more_horiz_rounded, color: p.secondaryLabel),
                  onSelected: (v) => switch (v) {
                    'up' => onMove(-1),
                    'down' => onMove(1),
                    'copy' => onDuplicate?.call(),
                    _ => onRemove(),
                  },
                  itemBuilder: (_) => [
                    if (index > 0)
                      const PopupMenuItem(
                        value: 'up',
                        child: Text('Posunout výš'),
                      ),
                    if (index < count - 1)
                      const PopupMenuItem(
                        value: 'down',
                        child: Text('Posunout níž'),
                      ),
                    if (onDuplicate != null)
                      const PopupMenuItem(
                        value: 'copy',
                        child: Text('Duplikovat den'),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        'Smazat den',
                        style: TextStyle(color: p.negative),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Space.m),
              child: TextField(
                controller: draft.name,
                maxLength: maxNameLength,
                textCapitalization: TextCapitalization.sentences,
                style: text.titleMedium,
                decoration: InputDecoration(
                  labelText: 'Název dne ${index + 1}',
                  hintText: 'Třeba Ramena a triceps',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: Space.s),
            for (var e = 0; e < draft.exercises.length; e++)
              _ExerciseRow(
                name: state.exercise(draft.exercises[e].exerciseId).name,
                plan: draft.exercises[e],
                onTap: () => onEditExercise(e),
              ),
            if (draft.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s),
                child: Text(
                  'Zatím žádný cvik.',
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
              ),
            TextButton.icon(
              onPressed: full ? null : onAddExercises,
              icon: const Icon(Icons.add_rounded),
              label: Text(full ? 'Den je plný' : 'Přidat cviky'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final String name;
  final PlannedExercise plan;
  final VoidCallback onTap;
  const _ExerciseRow({
    required this.name,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      button: true,
      label: '$name, ${planLabel(plan)}, upravit',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.palette.controlRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minTap),
          child: Padding(
            padding: const EdgeInsets.only(right: Space.s),
            child: Row(
              children: [
                Expanded(child: Text(name, style: text.bodyLarge)),
                Text(
                  planLabel(plan),
                  style: text.bodyMedium?.copyWith(
                    color: p.secondaryLabel,
                    fontFeatures: tabular,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.tertiaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Jak nový den vznikne.
enum _DayMode { suggest, own }

/// Nový den. Nahoře volba: nechat si cviky navrhnout podle partií
/// (a případně některé vyřadit), nebo si je vybrat ze seznamu.
class _AddDaySheet extends StatefulWidget {
  final AppState state;
  final int number;
  const _AddDaySheet({required this.state, required this.number});

  @override
  State<_AddDaySheet> createState() => _AddDaySheetState();
}

class _AddDaySheetState extends State<_AddDaySheet> {
  _DayMode _mode = _DayMode.suggest;
  final Set<String> _picked = {};

  /// Navržené cviky, které uživatel vyřadil.
  final Set<String> _dropped = {};

  String _count(int n) =>
      '$n ${n == 1
          ? 'cvik'
          : n < 5
          ? 'cviky'
          : 'cviků'}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    // Návrh dne bere jen cviky, na které má posilovna vybavení.
    final answers = widget.state.planAnswers;
    final raw = dayFromFocuses(_picked);
    final offered = answers == null || raw.exercises.isEmpty
        ? raw.exercises
        : personalizeDay(raw, answers).exercises;
    final kept = [
      for (final e in offered)
        if (!_dropped.contains(e.exerciseId)) e,
    ];
    final own = _mode == _DayMode.own;
    // Pevná výška: list neroste s náhledem, takže dlaždice nahoře stojí.
    // Tlačítko je pod posuvnou částí, takže je vidět pořád.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Den ${widget.number}', style: text.headlineSmall),
              const SizedBox(height: Space.m),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.auto_awesome_rounded,
                      color: p.accent,
                      label: 'Navrhnout cviky',
                      hint: 'Vybereš partie',
                      selected: !own,
                      onTap: () => setState(() => _mode = _DayMode.suggest),
                    ),
                  ),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.checklist_rounded,
                      color: AppPalette.violet,
                      label: 'Vyberu sám',
                      hint: 'Celý seznam cviků',
                      selected: own,
                      onTap: () => setState(() => _mode = _DayMode.own),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.m),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: Space.xs,
                    bottom: Space.m,
                  ),
                  child: own
                      ? Text(
                          'Otevřu seznam všech cviků. Vybereš jich, kolik '
                          'chceš, a den pak pojmenuješ.',
                          style: text.bodyMedium?.copyWith(
                            color: p.secondaryLabel,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Co ten den procvičíš? Klidně víc partií '
                              'najednou.',
                              style: text.bodyMedium?.copyWith(
                                color: p.secondaryLabel,
                              ),
                            ),
                            const SizedBox(height: Space.m),
                            MuscleTileGrid(
                              selected: _picked,
                              onToggle: (id) => setState(
                                () => _picked.contains(id)
                                    ? _picked.remove(id)
                                    : _picked.add(id),
                              ),
                            ),
                            const SizedBox(height: Space.l),
                            AnimatedSize(
                              duration: Motion.of(context, Motion.instant),
                              alignment: Alignment.topCenter,
                              child: offered.isEmpty
                                  ? const SizedBox(width: double.infinity)
                                  : _suggestions(context, raw.name, offered),
                            ),
                          ],
                        ),
                ),
              ),
              if (own)
                PrimaryButton(
                  'Vybrat cviky',
                  onPressed: () => popOnce(
                    context,
                    SplitDay('Den ${widget.number}', const []),
                  ),
                )
              else
                PrimaryButton(
                  _picked.isEmpty
                      ? 'Vyber partie'
                      : kept.isEmpty
                      ? 'Nech aspoň jeden cvik'
                      : 'Přidat den · ${_count(kept.length)}',
                  onPressed: kept.isEmpty
                      ? null
                      : () => popOnce(context, SplitDay(raw.name, kept)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navržené cviky; každý jde klepnutím vyřadit.
  Widget _suggestions(
    BuildContext context,
    String name,
    List<PlannedExercise> offered,
  ) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(name, style: text.titleMedium),
          ),
          Text(
            'Co nechceš, klepnutím vyřaď.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.xs),
          for (final e in offered)
            _SuggestedRow(
              name: widget.state.exercise(e.exerciseId).name,
              plan: planLabel(e),
              kept: !_dropped.contains(e.exerciseId),
              onTap: () => setState(() {
                if (!_dropped.remove(e.exerciseId)) _dropped.add(e.exerciseId);
              }),
            ),
        ],
      ),
    );
  }
}

/// Jedna ze dvou cest k novému dni; vybraná se zvedne a rozsvítí.
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(p.controlRadius + 4);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$label, $hint',
      excludeSemantics: true,
      child: PopSelect(
        selected: selected,
        child: PressScale(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1 : 0),
            duration: Motion.of(context, Motion.quick),
            curve: Motion.curve,
            builder: (context, t, _) => Raised(
              t: t,
              color: color,
              borderRadius: radius,
              child: Material(
                color: Color.lerp(
                  p.grouped,
                  Color.lerp(p.grouped, color, 0.18),
                  t,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    color: Color.lerp(p.separator, color, t)!,
                    width: 1 + t,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon,
                          color: Color.lerp(p.secondaryLabel, color, t),
                        ),
                        const SizedBox(height: Space.s),
                        Text(label, style: text.titleSmall),
                        Text(
                          hint,
                          style: text.bodySmall?.copyWith(
                            color: p.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navržený cvik; klepnutí ho z nového dne vyřadí nebo vrátí.
class _SuggestedRow extends StatelessWidget {
  final String name;
  final String plan;
  final bool kept;
  final VoidCallback onTap;
  const _SuggestedRow({
    required this.name,
    required this.plan,
    required this.kept,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      checked: kept,
      label: '$name, $plan',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(p.controlRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minTap),
          child: Row(
            children: [
              Icon(
                kept
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: kept ? p.accent : p.tertiaryLabel,
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Text(
                  name,
                  style: text.bodyMedium?.copyWith(
                    color: kept ? p.label : p.tertiaryLabel,
                  ),
                ),
              ),
              const SizedBox(width: Space.s),
              Text(
                plan,
                style: text.bodySmall?.copyWith(
                  color: kept ? p.secondaryLabel : p.tertiaryLabel,
                  fontFeatures: tabular,
                ),
              ),
              const SizedBox(width: Space.s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Série × opakování jednoho cviku a akce s ním. Změny hlásí hned
/// přes [onChanged]; vrací akci 'up' / 'down' / 'replace' / 'remove'.
class _ExerciseSheet extends StatefulWidget {
  final String name;
  final PlannedExercise initial;
  final bool canUp;
  final bool canDown;
  final ValueChanged<PlannedExercise> onChanged;
  const _ExerciseSheet({
    required this.name,
    required this.initial,
    required this.canUp,
    required this.canDown,
    required this.onChanged,
  });

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  late PlannedExercise _plan = widget.initial;

  void _set(PlannedExercise next) {
    setState(() => _plan = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    String sets(int n) =>
        n == 1 ? '1 série' : (n < 5 ? '$n série' : '$n sérií');
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.name, style: text.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(
              planLabel(_plan),
              style: text.bodyLarge?.copyWith(
                color: p.secondaryLabel,
                fontFeatures: tabular,
              ),
            ),
            const SizedBox(height: Space.l),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final (label, s, lo, hi) in _presets)
                  ChoiceChip(
                    label: Text('$label $s×$lo–$hi'),
                    selected:
                        _plan.sets == s &&
                        _plan.repMin == lo &&
                        _plan.repMax == hi,
                    onSelected: (_) =>
                        _set(_plan.copyWith(sets: s, repMin: lo, repMax: hi)),
                  ),
              ],
            ),
            const SizedBox(height: Space.l),
            Panel(
              child: Column(
                children: [
                  StepperControl(
                    label: 'Série',
                    value: _plan.sets,
                    min: 1,
                    max: 10,
                    spoken: sets,
                    onChanged: (n) => _set(_plan.copyWith(sets: n)),
                  ),
                  const SizedBox(height: Space.s),
                  StepperControl(
                    label: 'Opakování od',
                    value: _plan.repMin,
                    min: 1,
                    max: _plan.repMax,
                    onChanged: (n) => _set(_plan.copyWith(repMin: n)),
                  ),
                  const SizedBox(height: Space.s),
                  StepperControl(
                    label: 'Opakování do',
                    value: _plan.repMax,
                    min: _plan.repMin,
                    max: 50,
                    onChanged: (n) => _set(_plan.copyWith(repMax: n)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s),
            Text(
              'Když zvládneš horní hranici ve všech sériích, trenér přidá váhu.',
              style: text.bodySmall?.copyWith(color: p.secondaryLabel),
            ),
            const SizedBox(height: Space.l),
            GroupedSection(
              children: [
                GroupedRow(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Nahradit jiným cvikem',
                  onTap: () => popOnce(context, 'replace'),
                ),
                if (widget.canUp)
                  GroupedRow(
                    icon: Icons.arrow_upward_rounded,
                    title: 'Posunout výš',
                    chevron: false,
                    onTap: () => popOnce(context, 'up'),
                  ),
                if (widget.canDown)
                  GroupedRow(
                    icon: Icons.arrow_downward_rounded,
                    title: 'Posunout níž',
                    chevron: false,
                    onTap: () => popOnce(context, 'down'),
                  ),
                GroupedRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'Odebrat ze dne',
                  destructive: true,
                  chevron: false,
                  onTap: () => popOnce(context, 'remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

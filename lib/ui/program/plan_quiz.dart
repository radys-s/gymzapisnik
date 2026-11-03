import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/splits.dart';
import '../../domain/catalog.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Otázky dotazníku „Tvůj plán“: cíl, dny v týdnu, zkušenost a čas.
/// Stejný formulář je v úvodu aplikace i v Programu.
class PlanQuizForm extends StatelessWidget {
  final PlanAnswers answers;
  final ValueChanged<PlanAnswers> onChanged;
  const PlanQuizForm({
    super.key,
    required this.answers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget check(bool on) => on
        ? Icon(Icons.check_rounded, color: p.accent)
        : const SizedBox(width: 24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(
          header: 'Co chceš hlavně',
          children: [
            for (final g in PlanGoal.values)
              GroupedRow(
                title: g.label,
                subtitle: g.hint,
                trailing: check(g == answers.goal),
                onTap: () => onChanged(answers.copyWith(goal: g)),
              ),
          ],
        ),
        GroupedSection(
          header: 'Kolikrát týdně můžeš cvičit',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: SegmentedButton<int>(
                segments: [
                  for (var d = 2; d <= 6; d++)
                    ButtonSegment(value: d, label: Text('$d×')),
                ],
                selected: {answers.days},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    onChanged(answers.copyWith(days: s.single)),
              ),
            ),
          ],
        ),
        GroupedSection(
          header: 'Jak dlouho cvičíš',
          children: [
            for (final e in Experience.values)
              GroupedRow(
                title: e.label,
                subtitle: e.hint,
                trailing: check(e == answers.experience),
                onTap: () => onChanged(answers.copyWith(experience: e)),
              ),
          ],
        ),
        GroupedSection(
          header: 'Kolik minut máš na trénink',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: SegmentedButton<int>(
                segments: [
                  for (final m in planMinutes)
                    ButtonSegment(value: m, label: Text('$m')),
                ],
                selected: {answers.minutes},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    onChanged(answers.copyWith(minutes: s.single)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kde a jak cvičí: vybavení, priority, šetřené klouby a oblíbené cviky.
/// Plán podle toho vymění cviky, které nejdou udělat nebo bolí.
class PlanPrefsForm extends StatelessWidget {
  final PlanAnswers answers;
  final ValueChanged<PlanAnswers> onChanged;
  const PlanPrefsForm({
    super.key,
    required this.answers,
    required this.onChanged,
  });

  Set<T> _toggle<T>(Set<T> set, T v) =>
      set.contains(v) ? ({...set}..remove(v)) : {...set, v};

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = answers;
    Widget check(bool on) => on
        ? Icon(Icons.check_rounded, color: p.accent)
        : const SizedBox(width: 24);
    Widget chips(List<Widget> children) => Padding(
      padding: const EdgeInsets.all(Space.m),
      child: Wrap(spacing: Space.s, runSpacing: Space.s, children: children),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(
          header: 'Kde cvičíš',
          children: [
            for (final place in TrainingPlace.values)
              GroupedRow(
                title: place.label,
                subtitle: place.hint,
                trailing: check(place == a.place),
                onTap: () => onChanged(a.copyWith(place: place)),
              ),
          ],
        ),
        GroupedSection(
          header: 'Na co se chceš zaměřit',
          footer: 'Nepovinné. Vybrané partie dostanou v plánu sérii navíc.',
          children: [
            chips([
              for (final f in focusChoices)
                FilterChip(
                  label: Text(focusName(f)),
                  selected: a.focus.contains(f),
                  onSelected: (_) =>
                      onChanged(a.copyWith(focus: _toggle(a.focus, f))),
                ),
            ]),
          ],
        ),
        GroupedSection(
          header: 'Co tě bolí nebo chceš šetřit',
          footer:
              'Nepovinné. Cviky, které kloub nejvíc zatěžují, plán vymění '
              'za šetrnější. Při bolesti se poraď s lékařem nebo '
              'fyzioterapeutem.',
          children: [
            chips([
              for (final j in Joint.values)
                FilterChip(
                  label: Text(j.label),
                  selected: a.avoid.contains(j),
                  onSelected: (_) =>
                      onChanged(a.copyWith(avoid: _toggle(a.avoid, j))),
                ),
            ]),
          ],
        ),
        GroupedSection(
          header: 'Cviky, které chceš mít v plánu',
          footer: 'Nepovinné. Nahradí cvik na stejný sval.',
          children: [
            chips([
              for (final id in favoriteChoices)
                if (findExercise(id, const []) case final e?)
                  FilterChip(
                    label: Text(e.name),
                    selected: a.favorites.contains(id),
                    onSelected: (_) => onChanged(
                      a.copyWith(favorites: _toggle(a.favorites, id)),
                    ),
                  ),
            ]),
          ],
        ),
      ],
    );
  }
}

/// Údaje o těle pro přesnější kalorie: pohlaví, výška, rok narození
/// a co chce s váhou. Všechno nepovinné.
class BodyForm extends StatefulWidget {
  final PlanAnswers answers;
  final ValueChanged<PlanAnswers> onChanged;

  /// Kalorie jen pro dospělé: mladším se cíl váhy nenabízí. Null znamená,
  /// že souhlas s věkem ještě nepadl (úvod) a rozhoduje rok narození.
  final bool? adult;
  const BodyForm({
    super.key,
    required this.answers,
    required this.onChanged,
    required this.adult,
  });

  @override
  State<BodyForm> createState() => _BodyFormState();
}

class _BodyFormState extends State<BodyForm> {
  late final _height = TextEditingController(
    text: widget.answers.heightCm?.toString() ?? '',
  );
  late final _year = TextEditingController(
    text: widget.answers.birthYear?.toString() ?? '',
  );

  @override
  void dispose() {
    _height.dispose();
    _year.dispose();
    super.dispose();
  }

  static int? _int(String raw, int min, int max) {
    final v = int.tryParse(raw.trim());
    return v != null && v >= min && v <= max ? v : null;
  }

  static int get _thisYear => DateTime.now().year;

  /// Z roku narození jde věk určit jen na rok přesně: 18 let jistě má
  /// až ten, komu letos bude 19.
  bool _goalAllowed(int? birthYear) =>
      widget.adult ?? (birthYear != null && _thisYear - birthYear >= 19);

  void _emit({
    Sex? sex,
    WeightGoal? goal,
    bool clearSex = false,
    bool clearGoal = false,
  }) {
    final a = widget.answers;
    final year = _int(_year.text, _thisYear - 100, _thisYear - 10);
    widget.onChanged(
      a.withBody(
        sex: clearSex ? null : sex ?? a.sex,
        heightCm: _int(_height.text, 120, 230),
        birthYear: year,
        weightGoal: clearGoal || !_goalAllowed(year)
            ? null
            : goal ?? a.weightGoal,
      ),
    );
  }

  Widget _field(
    TextEditingController c, {
    required String label,
    required String hint,
    String? suffix,
    required bool bad,
    required String error,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.m),
    child: Semantics(
      // Nápověda po psaní zmizí, čtečka potřebuje stálý název.
      label: label,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        onChanged: (_) => _emit(),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix,
          border: InputBorder.none,
          errorText: bad ? error : null,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final a = widget.answers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(
          header: 'Pohlaví',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: SegmentedButton<Sex?>(
                segments: [
                  for (final s in Sex.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                  const ButtonSegment(value: null, label: Text('Neuvádět')),
                ],
                selected: {a.sex},
                showSelectedIcon: false,
                onSelectionChanged: (s) => s.single == null
                    ? _emit(clearSex: true)
                    : _emit(sex: s.single),
              ),
            ),
          ],
        ),
        GroupedSection(
          header: 'Výška a věk',
          footer:
              'Nepovinné. S výškou, věkem a pohlavím spočítám kalorie '
              'přesněji než jen z váhy.',
          children: [
            _field(
              _height,
              label: 'Výška v cm',
              hint: 'Výška, např. 180',
              suffix: 'cm',
              bad: _height.text.trim().isNotEmpty && a.heightCm == null,
              error: 'Zadej výšku 120–230 cm.',
            ),
            _field(
              _year,
              label: 'Rok narození',
              hint: 'Rok narození, např. 2007',
              bad: _year.text.trim().isNotEmpty && a.birthYear == null,
              error: 'Zadej rok narození, třeba 2007.',
            ),
          ],
        ),
        if (_goalAllowed(a.birthYear))
          GroupedSection(
            header: 'S váhou chci',
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.m),
                child: SegmentedButton<WeightGoal>(
                  segments: [
                    for (final g in WeightGoal.values)
                      ButtonSegment(value: g, label: Text(g.label)),
                  ],
                  emptySelectionAllowed: true,
                  selected: {?a.weightGoal},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => s.isEmpty
                      ? _emit(clearGoal: true)
                      : _emit(goal: s.single),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Shrnutí doporučení: program, proč právě on a kolik cviků.
class PlanPreview extends StatelessWidget {
  final PlanRecommendation recommendation;
  const PlanPreview(this.recommendation, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = recommendation;
    final split = findSplit(r.splitId);
    return HeroCard(
      vivid: true,
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doporučeno pro tebe',
              style: text.labelMedium?.copyWith(
                color: context.palette.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(split?.name ?? r.splitId, style: text.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(
              planFacts(r),
              style: text.bodyMedium?.copyWith(fontFeatures: tabular),
            ),
            const SizedBox(height: Space.s),
            Text(
              r.why,
              style: text.bodyMedium?.copyWith(
                color: context.palette.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// „3× týdně · 5 cviků · pauza 2 min“.
String planFacts(PlanRecommendation r) {
  final rest = r.restSeconds % 60 == 0
      ? '${r.restSeconds ~/ 60} min'
      : '${r.restSeconds} s';
  return '${r.perWeek}× týdně · ${r.exercises} ${_cviku(r.exercises)} · '
      'pauza $rest';
}

String _cviku(int n) => n == 1
    ? 'cvik'
    : n < 5
    ? 'cviky'
    : 'cviků';

/// Samostatná obrazovka dotazníku (z Programu nebo z hlavní karty).
class PlanQuizPage extends StatefulWidget {
  final AppState state;
  const PlanQuizPage(this.state, {super.key});

  @override
  State<PlanQuizPage> createState() => _PlanQuizPageState();
}

class _PlanQuizPageState extends State<PlanQuizPage> {
  late PlanAnswers answers = widget.state.planAnswers ?? const PlanAnswers();
  bool saving = false;

  Future<void> _apply() async {
    setState(() => saving = true);
    try {
      final r = await widget.state.applyPlan(answers);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Program ${findSplit(r.splitId)?.name ?? ''} je nastavený.',
            ),
          ),
        );
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => LargeTitlePage(
    title: 'Tvůj plán',
    children: [
      PlanQuizForm(
        answers: answers,
        onChanged: (a) => setState(() => answers = a),
      ),
      PlanPrefsForm(
        answers: answers,
        onChanged: (a) => setState(() => answers = a),
      ),
      BodyForm(
        answers: answers,
        adult: widget.state.profile.adult,
        onChanged: (a) => setState(() => answers = a),
      ),
      const SizedBox(height: Space.l),
      PlanPreview(recommendPlan(answers)),
      const SizedBox(height: Space.l),
      PrimaryButton('Použít plán', busy: saving, onPressed: _apply),
      const SizedBox(height: Space.xxl),
    ],
  );
}

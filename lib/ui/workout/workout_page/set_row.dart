part of '../workout_page.dart';

// Řádek jedné série.

class _SetRow extends StatefulWidget {
  final AppState state;
  final SetEntry set;
  final String label;
  final bool bodyweight;
  final SetEntry? previous;
  final VoidCallback onRemove;
  final ValueChanged<String> onError;

  /// Název cviku do nadpisu listu úprav.
  final String exercise;

  const _SetRow({
    super.key,
    this.exercise = '',
    required this.state,
    required this.set,
    required this.label,
    required this.bodyweight,
    required this.previous,
    required this.onRemove,
    required this.onError,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final weight = TextEditingController(text: _kgText(widget.set.weight));
  late final reps = TextEditingController(text: _repsText(widget.set.reps));
  bool _saving = false;
  Timer? _toggleCooldown;

  static String _kgText(double v) => v == 0 ? '' : formatKg(v);
  static String _repsText(int v) => v == 0 ? '' : '$v';

  /// Název série pro čtečku obrazovky.
  String get _name => setName(widget.set, widget.label);

  /// Hodnoty se mohou změnit zvenku (přenos z předchozí série).
  @override
  void didUpdateWidget(_SetRow old) {
    super.didUpdateWidget(old);
    final w = _kgText(widget.set.weight);
    final r = _repsText(widget.set.reps);
    if (parseNum(weight.text) != parseNum(w)) weight.text = w;
    if (reps.text != r) reps.text = r;
  }

  @override
  void dispose() {
    _toggleCooldown?.cancel();
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  Future<void> _persist(Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {
      if (mounted) {
        widget.onError(
          'Změnu se nepodařilo uložit. Zkus ji znovu; aplikaci zatím nezavírej.',
        );
      }
    }
  }

  Future<void> _toggleDone() async {
    if (_saving || (_toggleCooldown?.isActive ?? false)) {
      return;
    }
    _toggleCooldown = Timer(const Duration(milliseconds: 300), () {});
    setState(() => _saving = true);
    try {
      final error = await widget.state.toggleDone(widget.set);
      if (error != null && mounted) widget.onError(error);
      final records = widget.state.liveRecords(widget.set);
      if (error == null && widget.set.done && mounted) {
        if (records.isEmpty) {
          Haptics.confirm();
        } else {
          Haptics.record();
          _celebrate(records);
        }
      }
    } catch (_) {
      if (mounted) {
        widget.onError(
          'Sérii se nepodařilo uložit. Zkus zápis znovu; aplikaci zatím nezavírej.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _celebrate(List<RecordKind> records) {
    final p = context.palette;
    // Bez hideCurrentSnackBar: nabídka „Vrátit“ po smazání musí zůstat.
    // Krátké trvání, ať se série rekordů nehromadí ve frontě.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: p.gold),
            const SizedBox(width: Space.s),
            Expanded(
              child: Text(
                'Nový osobní rekord: '
                '${records.map((r) => r.label.toLowerCase()).join(', ')}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List s velkými čísly a − / +. Změny se ukládají hned jako psaní.
  Future<void> _openSheet({bool focusReps = false}) {
    // Které série jdou s touto: určí se jednou při otevření, ne po každém
    // napsaném znaku (jinak by mezistav „2“ chytil ručně zadanou dvojku).
    final followers = widget.state.followersOf(widget.set);
    return showSetSheet(
      context,
      title: widget.exercise.isEmpty ? _name : '${widget.exercise} · $_name',
      weight: weight.text,
      reps: reps.text,
      step: widget.state.profile.weightStep,
      bodyweight: widget.bodyweight,
      focusReps: focusReps,
      // Zapisuje rovnou do série, i kdyby se řádek mezitím přestavěl.
      // List čísla ověří předem; chybu uložení ukáže sám.
      onChanged: (w, r) async {
        final set = widget.set;
        final state = widget.state;
        set
          ..weight = parseNum(w) ?? 0
          ..reps = int.tryParse(r.trim()) ?? 0;
        // Další série téhož cviku dostanou stejné hodnoty (když je nikdo
        // ručně nezměnil): začátečník nemusí přepisovat každou zvlášť.
        state.carryForward(set, followers);
        if (mounted) {
          weight.text = w;
          reps.text = r;
        }
        try {
          await state.saveActive();
          return true;
        } catch (_) {
          return false;
        }
      },
    );
  }

  void _typeMenu(String action) => switch (action) {
    'working' => _persist(() => widget.state.setWarmup(widget.set, false)),
    'warmup' => _persist(() => widget.state.setWarmup(widget.set, true)),
    'drop' => _persist(() => widget.state.setKind(widget.set, SetKind.drop)),
    'failure' => _persist(
      () => widget.state.setKind(widget.set, SetKind.failure),
    ),
    _ => widget.onRemove(),
  };

  Widget _field(
    TextEditingController c, {
    required String label,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: ListenableBuilder(
      listenable: c,
      builder: (context, field) => Semantics(
        container: true,
        label: label,
        value: c.text.isEmpty ? '0' : c.text,
        hint: 'Otevře úpravu série',
        button: true,
        onTap: () => _openSheet(focusReps: !decimal),
        child: ExcludeSemantics(child: field),
      ),
      // Pole jen ukazuje hodnotu, klepnutí otevře list s − / +.
      child: TextField(
        controller: c,
        readOnly: true,
        // Bez fokusu: po zavření listu nezůstane pole zvýrazněné.
        canRequestFocus: false,
        showCursor: false,
        enableInteractiveSelection: false,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontFeatures: tabular),
        decoration: const InputDecoration(
          hintText: '0',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
        onTap: () => _openSheet(focusReps: !decimal),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final set = widget.set;
    final prev = widget.previous;
    final kgLabel = widget.bodyweight ? 'Přidaná váha v kg' : 'Váha v kg';
    final record = set.done && widget.state.liveRecords(set).isNotEmpty;
    return Dismissible(
      key: ObjectKey(set),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.xl),
        decoration: BoxDecoration(
          color: p.negative,
          borderRadius: BorderRadius.circular(context.palette.controlRadius),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => widget.onRemove(),
      // Potvrzení: řádek se plynule podbarví, fajfka naskočí.
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.quick),
        curve: Motion.curve,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.only(right: _edgeInset),
        decoration: BoxDecoration(
          color: set.done ? p.accent.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(context.palette.controlRadius),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _typeWidth,
              height: minTap,
              // Vlastní uzel, jinak se tlačítko slije s textem „Minule".
              child: Semantics(
                container: true,
                button: true,
                child: PopupMenuButton<String>(
                  tooltip: '$_name, změnit typ',
                  padding: EdgeInsets.zero,
                  onSelected: _typeMenu,
                  itemBuilder: (_) => [
                    ...setTypeItems(set),
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
                      constraints: const BoxConstraints(minWidth: _badgeWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: record
                            ? p.gold.withValues(alpha: 0.2)
                            : set.warmup || set.kind != SetKind.normal
                            ? p.accent.withValues(alpha: 0.16)
                            : p.fill,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      // Rekordní série má místo čísla pohár.
                      child: record
                          ? Icon(
                              Icons.emoji_events_rounded,
                              size: 18,
                              color: p.gold,
                              semanticLabel: 'Osobní rekord',
                            )
                          : Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: text.titleSmall?.copyWith(
                                color: set.warmup || set.kind != SetKind.normal
                                    ? p.accent
                                    : p.label,
                                fontFeatures: tabular,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              // Celé číslo i na úzkém displeji: radši menší než useknuté.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  prev == null ? '–' : '${formatKg(prev.weight)}×${prev.reps}',
                  semanticsLabel: prev == null
                      ? 'Minule nic'
                      : 'Minule ${formatKg(prev.weight)} kg, ${prev.reps} opakování',
                  maxLines: 1,
                  style: text.bodyMedium?.copyWith(
                    color: p.secondaryLabel,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _field(weight, label: '$kgLabel, $_name', decimal: true),
            ),
            Expanded(flex: 3, child: _field(reps, label: 'Opakování, $_name')),
            Container(
              width: _doneWidth,
              height: 48,
              padding: const EdgeInsets.only(left: Space.xs),
              // Potvrzená série svítí přechodem motivu.
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.quick),
                curve: Motion.curve,
                decoration: BoxDecoration(
                  gradient: set.done ? p.linear : null,
                  color: set.done ? null : p.fill,
                  borderRadius: BorderRadius.circular(
                    context.palette.controlRadius,
                  ),
                ),
                // Bez tooltipu: na webu po potvrzení visel přes další řádek.
                // Vlastní uzel s akcí, jinak splyne s řádkem a čtečka
                // sérii nepotvrdí.
                child: Semantics(
                  container: true,
                  button: true,
                  label: set.done ? 'Zrušit potvrzení' : 'Potvrdit sérii',
                  onTap: _saving ? null : _toggleDone,
                  excludeSemantics: true,
                  child: IconButton(
                    onPressed: _saving ? null : _toggleDone,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: set.done
                          ? p.onGradient
                          : p.secondaryLabel,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.palette.controlRadius,
                        ),
                      ),
                    ),
                    icon: AnimatedScale(
                      scale: set.done ? 1 : 0.8,
                      duration: Motion.of(context, Motion.base),
                      curve: Curves.elasticOut,
                      child: const Icon(Icons.check_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

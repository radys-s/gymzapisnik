import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Jeden zdroj pravdy pro pohyb: doby, křivka a rozestupy.
///
/// Pohyb má ukázat, co se právě změnilo (potvrzená série, nový rekord),
/// ne zdobit. Při „omezit animace“ v systému je všechno okamžité.
abstract final class Motion {
  /// Odezva na stisk.
  static const instant = Duration(milliseconds: 120);

  /// Hover, odchod prvku, přepnutí stavu.
  static const quick = Duration(milliseconds: 280);

  /// Vstup prvku, standard.
  static const base = Duration(milliseconds: 450);

  /// Větší bloky, počítadla.
  static const slow = Duration(milliseconds: 700);

  /// Potvrzení série: dost na to, aby bylo vidět, nikdy nebrzdí další klik.
  static const setDone = Duration(milliseconds: 400);

  /// Oslava v souhrnu (rekord, dokreslený kruh).
  static const celebrate = Duration(milliseconds: 1100);

  /// Rychlý nájezd, klidné dosednutí.
  static const curve = Cubic(0.22, 1, 0.36, 1);

  /// Rozestup mezi sourozenci ve skupině.
  static const stagger = Duration(milliseconds: 70);

  /// Krok postupně odhalovaného souhrnu: kratší než [base], ať se bloky
  /// překrývají a sekvence nikdy nestojí.
  static const stage = Duration(milliseconds: 320);

  /// Má se animovat? Ne, když si uživatel v systému omezil animace.
  static bool on(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// Doba [d], nebo nula při omezených animacích.
  static Duration of(BuildContext context, Duration d) =>
      on(context) ? d : Duration.zero;
}

/// Prvek, který jednou vjede zespodu a zprůhlední se do plna.
///
/// Obsah je v DOM i během animace (jen `opacity` a `transform`); při
/// omezených animacích se ukáže hned.
class Reveal extends StatefulWidget {
  final Widget child;

  /// Pořadí ve skupině: zpoždění = index × [Motion.stagger].
  final int index;
  final double offset;

  /// Rozestup místo [Motion.stagger] (postupný souhrn).
  final Duration? step;

  /// Když přepne na true, prvek se ukáže hned (přeskočení sekvence).
  final ValueListenable<bool>? skip;

  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 16,
    this.step,
    this.skip,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.base,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Motion.curve,
  );
  bool _started = false;
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.on(context) || (widget.skip?.value ?? false)) {
      _c.value = 1;
      return;
    }
    widget.skip?.addListener(_onSkip);
    // Strop zpoždění: dlouhý seznam nesmí čekat sekundy na poslední řádek.
    _delay = Timer(
      (widget.step ?? Motion.stagger) * widget.index.clamp(0, 8),
      _c.forward,
    );
  }

  @override
  void didUpdateWidget(Reveal old) {
    super.didUpdateWidget(old);
    if (identical(old.skip, widget.skip)) return;
    old.skip?.removeListener(_onSkip);
    if (_c.isCompleted) return;
    widget.skip?.addListener(_onSkip);
    _onSkip();
  }

  void _onSkip() {
    if (!(widget.skip?.value ?? false)) return;
    _delay?.cancel();
    _c.value = 1;
  }

  @override
  void dispose() {
    widget.skip?.removeListener(_onSkip);
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _t.value) * widget.offset),
        child: child,
      ),
    ),
  );
}

/// Číslo, které při prvním zobrazení napočítá od nuly k cíli.
///
/// Čtečka obrazovky dostane jen konečnou hodnotu, ne každý snímek.
class CountUp extends StatelessWidget {
  final double value;
  final String Function(double v) format;
  final TextStyle? style;

  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: format(value),
    excludeSemantics: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: Motion.on(context) ? 0 : value, end: value),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      builder: (_, v, _) => Text(format(v), style: style),
    ),
  );
}

/// Sloupec, jehož děti vjedou postupně za sebou (jednou, při prvním
/// zobrazení). Mezery dělá [gap], ne okraje dětí.
class StaggerColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final double gap;

  /// Posun indexů, když sloupec navazuje na jiné postupné prvky.
  final int startIndex;

  const StaggerColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.gap = 0,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0 && gap > 0) SizedBox(height: gap),
        Reveal(index: startIndex + i, child: children[i]),
      ],
    ],
  );
}

/// Při stisku se obsah lehce zmenší (0,97) – hmatový pocit tlačítka bez
/// vibrace. Gesta neodchytává, jen poslouchá ukazatel.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !Motion.on(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? Motion.instant : Motion.quick,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Krátké „poskočení“ (1 → 1,06 → 1), když se [selected] zapne.
/// Velikost v layoutu se nemění, jen kreslení.
class PopSelect extends StatefulWidget {
  final bool selected;
  final Widget child;
  const PopSelect({super.key, required this.selected, required this.child});

  @override
  State<PopSelect> createState() => _PopSelectState();
}

class _PopSelectState extends State<PopSelect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.quick,
  );
  late final Animation<double> _s = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 40),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Motion.curve)),
      weight: 60,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(PopSelect old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && Motion.on(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _s, child: widget.child);
}

/// IndexedStack, jehož nově zvolené dítě se prolne (a lehce vyjede).
/// Stav záložek zůstává jako u IndexedStack.
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.quick,
    value: 1,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Motion.curve,
  );

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index && Motion.on(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (_, child) => Opacity(
      opacity: 0.2 + 0.8 * _t.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _t.value) * 8),
        child: child,
      ),
    ),
    child: IndexedStack(index: widget.index, children: widget.children),
  );
}

/// Značky pro sdílené přechody (Hero) – jedna funkce, ať se nerozejdou.
String heroTag(String kind, Object id) => 'hero:$kind:$id';

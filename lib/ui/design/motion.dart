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

  /// Rychlý nájezd, klidné dosednutí.
  static const curve = Cubic(0.22, 1, 0.36, 1);

  /// Rozestup mezi sourozenci ve skupině.
  static const stagger = Duration(milliseconds: 70);

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

  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 16,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.on(context)) {
      _c.value = 1;
      return;
    }
    Future.delayed(Motion.stagger * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
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

part of '../components.dart';

// Panely, kruh postupu, štítky, statistiky a prázdný stav.

/// Card body shared by panels, grouped lists, and hero cards: rounded
/// outline, a faint light from the top-left corner, and a soft shadow.
class CardSurface extends StatelessWidget {
  final Widget child;

  /// Tints the lit corner with the section color.
  final Tone? tone;
  const CardSurface({super.key, required this.child, this.tone});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: p.cardRadius(),
        boxShadow: p.cardShadow,
      ),
      child: Material(
        color: p.grouped,
        shape: p.cardShape(),
        clipBehavior: Clip.antiAlias,
        // Ink paints on the card itself, so tap ripples stay visible.
        child: Ink(
          decoration: BoxDecoration(gradient: p.surface(tone)),
          child: child,
        ),
      ),
    );
  }
}

/// Obyčejná seskupená karta.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  /// Barva sekce v rohu karty.
  final Tone? tone;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.l),
    this.onTap,
    this.tone,
  });

  @override
  Widget build(BuildContext context) => PressScale(
    enabled: onTap != null,
    scale: 0.985,
    child: CardSurface(
      tone: tone,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Kruh postupu s přechodem barev motivu.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Widget? child;

  /// Barvy oblouku; bez nich přechod z palety.
  final List<Color>? colors;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.stroke = 8,
    this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: size,
      // Při prvním zobrazení se oblouk dokreslí od nuly, pak plynule
      // navazuje na každou změnu.
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: Motion.on(context) ? 0 : value.clamp(0, 1).toDouble(),
          end: value.clamp(0, 1).toDouble(),
        ),
        duration: Motion.of(context, Motion.slow),
        curve: Motion.curve,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke, p.fill, colors ?? p.gradient),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color track;
  final List<Color> colors;
  _RingPainter(this.value, this.stroke, this.track, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    final sweep = math.pi * 2 * value;
    canvas.drawArc(
      ring,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [...colors, colors.first],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.colors != colors;
}

/// Malý štítek („Rekord", „Rozcvička").
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  const Pill(this.label, {super.key, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: c, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hodnota s popiskem pod sebou („3/4 · tréninky").
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final CrossAxisAlignment align;

  /// Když je zadané, hodnota při prvním zobrazení napočítá k [countTo]
  /// a vypíše se přes [format] (jinak se ukáže [value]).
  final double? countTo;
  final String Function(double v)? format;

  /// Velké číslo jako na výsledkové tabuli (souhrn v telemetrických vzhledech).
  final bool big;
  const StatTile(
    this.value,
    this.label, {
    super.key,
    this.align = CrossAxisAlignment.start,
    this.countTo,
    this.format,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valueStyle = (big ? text.headlineMedium : text.titleLarge)?.copyWith(
      fontFeatures: tabular,
    );
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Velké písmo hodnotu zmenší, místo aby ji usekl.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: countTo != null && format != null
              ? CountUp(value: countTo!, format: format!, style: valueStyle)
              : Text(value, style: valueStyle, maxLines: 1),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(label, style: text.labelMedium, maxLines: 1),
        ),
      ],
    );
  }
}

/// Prázdný stav: ikona, nadpis, jedna věta, volitelná akce.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xxl,
        vertical: Space.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: p.tertiaryLabel),
          const SizedBox(height: Space.m),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Space.xs),
          Text(
            message,
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: Space.l), action!],
        ],
      ),
    );
  }
}

/// Logo aplikace: tmavá dlaždice s kruhem postupu a činkou.
class AppMark extends StatelessWidget {
  final double size;

  /// Barevná záře pod dlaždicí (uvítání); malé značky jsou bez ní.
  final bool glow;
  const AppMark({super.key, this.size = 88, this.glow = false});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.225),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppPalette.violet.withValues(alpha: 0.38),
                  blurRadius: size * 0.42,
                  spreadRadius: -size * 0.1,
                  offset: Offset(0, size * 0.14),
                ),
              ]
            : null,
      ),
      child: const CustomPaint(painter: BrandPainter()),
    ),
  );
}

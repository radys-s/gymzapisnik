part of '../components.dart';

// Panely, kruh postupu, štítky, statistiky a prázdný stav.

/// Obyčejná seskupená karta.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.l),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    );
    return PressScale(
      enabled: onTap != null,
      scale: 0.985,
      child: Material(
        color: p.grouped,
        shape: p.cardShape(),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
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

/// Logo aplikace: zaoblený čtverec v barvách motivu se značkou.
class AppMark extends StatelessWidget {
  final double size;
  const AppMark({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: p.linear,
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: CustomPaint(painter: _MarkPainter(p.onGradient)),
    );
  }
}

/// Značka: osa činky se dvěma kotouči.
class _MarkPainter extends CustomPainter {
  final Color color;
  _MarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final paint = Paint()..color = color;
    // Průhlednost na celou vrstvu, aby překryvy osy a kotoučů neztmavly.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.85),
    );
    RRect r(double x, double y, double w, double h, double rad) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * u, y * u, w * u, h * u),
          Radius.circular(rad * u),
        );
    canvas
      ..drawRRect(r(28, 46, 44, 8, 4), paint)
      ..drawRRect(r(24, 30, 10, 40, 5), paint)
      ..drawRRect(r(66, 30, 10, 40, 5), paint)
      ..drawRRect(r(14, 38, 8, 24, 4), paint)
      ..drawRRect(r(78, 38, 8, 24, 4), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

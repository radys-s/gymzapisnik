import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoDialogAction;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Stránka s velkým nadpisem (iOS): nadpis 34 pt v obsahu, po posunu
/// se objeví malý nadpis v liště a pod ní tenká linka.
class LargeTitlePage extends StatefulWidget {
  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  final ScrollController? controller;

  const LargeTitlePage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(
      Space.page,
      Space.s,
      Space.page,
      Space.xxxl,
    ),
    this.controller,
  });

  @override
  State<LargeTitlePage> createState() => _LargeTitlePageState();
}

class _LargeTitlePageState extends State<LargeTitlePage> {
  /// Posun, od kterého je velký nadpis schovaný pod lištou.
  static const _collapseAt = 34.0;
  bool collapsed = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final now = n.metrics.pixels > _collapseAt;
    if (now != collapsed) setState(() => collapsed = now);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      bottomNavigationBar: widget.bottom,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          controller: widget.controller,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: p.background,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: collapsed ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: ExcludeSemantics(
                  excluding: !collapsed,
                  child: Text(widget.title),
                ),
              ),
              actions: [
                ...widget.actions,
                const SizedBox(width: Space.xs),
              ],
              shape: Border(
                bottom: BorderSide(
                  color: collapsed ? p.separator : Colors.transparent,
                  width: 0.5,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.page + Space.xs,
                  0,
                  Space.page,
                  Space.xs,
                ),
                child: Semantics(
                  container: true,
                  header: true,
                  child: Text(widget.title, style: text.headlineLarge),
                ),
              ),
            ),
            SliverPadding(
              padding: widget.padding,
              sliver: SliverList.list(children: widget.children),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nadpis sekce s volitelným odkazem vpravo („Vše").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl, 0, Space.s),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            container: true,
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: Space.s),
            ),
            child: Text(action!),
          ),
      ],
    ),
  );
}

/// Seskupený seznam jako v Nastavení iPhonu: řádky v jedné kartě,
/// oddělené tenkou čárou, s popiskem nad a pod.
class GroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  /// Odsazení oddělovače zleva (u řádků s ikonou větší).
  final double dividerIndent;

  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.dividerIndent = Space.l,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(indent: dividerIndent));
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, 6),
              child: Semantics(
                container: true,
                header: true,
                child: Text(header!, style: text.bodySmall),
              ),
            ),
          Material(
            color: p.grouped,
            borderRadius: BorderRadius.circular(Radii.card),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 6, Space.l, 0),
              child: Text(footer!, style: text.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Řádek seskupeného seznamu: barevná ikona, text, hodnota, šipka.
class GroupedRow extends StatelessWidget {
  final IconData? icon;

  /// Vlastní prvek vlevo místo ikony (např. vzorek barvy).
  final Widget? leading;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool? chevron;

  const GroupedRow({
    super.key,
    this.icon,
    this.leading,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.chevron,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final showChevron = chevron ?? (onTap != null && trailing == null);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minTap + 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: 10,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: Space.m),
              ] else if (icon != null) ...[
                IconTile(icon!, color: iconColor ?? p.accent),
                const SizedBox(width: Space.m),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.bodyLarge?.copyWith(
                        color: destructive ? p.negative : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: Space.s),
                // Hodnota drží u pravého okraje; dlouhá se zkrátí.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      color: p.secondaryLabel,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: Space.s),
                trailing!,
              ],
              if (showChevron) ...[
                const SizedBox(width: Space.xs),
                Icon(Icons.chevron_right, size: 22, color: p.tertiaryLabel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Malá barevná dlaždice s bílou ikonou (styl Nastavení iPhonu).
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconTile(this.icon, {super.key, required this.color, this.size = 30});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.26),
    ),
    child: Icon(icon, size: size * 0.6, color: Colors.white),
  );
}

/// Hlavní akce obrazovky: přechod barev motivu, černý text.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !busy;
    final fg = enabled ? p.onAccent : p.tertiaryLabel;
    // Vlastní uzel: jinak se popisek slije do rodiče přes celou obrazovku.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: enabled ? p.linear : null,
            color: enabled ? null : p.fill,
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.control),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: busy
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: p.secondaryLabel,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: fg, size: 22),
                          const SizedBox(width: Space.s),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: fg),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vedlejší akce stejné velikosti jako hlavní (šedé pozadí, barevný text).
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool destructive;

  const SecondaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = OutlinedButton.styleFrom(
      foregroundColor: destructive ? p.negative : p.accent,
      minimumSize: const Size.fromHeight(52),
    );
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
  }
}

/// Výrazná karta pro to nejdůležitější na obrazovce (větší zaoblení).
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.palette.grouped,
      borderRadius: BorderRadius.circular(Radii.hero),
    ),
    child: child,
  );
}

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
  Widget build(BuildContext context) => Material(
    color: context.palette.grouped,
    borderRadius: BorderRadius.circular(Radii.card),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Kruh postupu s přechodem barev motivu.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.stroke = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke, p.fill, p.gradient),
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
  const StatTile(
    this.value,
    this.label, {
    super.key,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: text.titleLarge?.copyWith(fontFeatures: tabular),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: text.labelMedium),
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
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

/// Značka: osa činky se dvěma kotouči.
class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final paint = Paint()..color = Colors.black;
    // Průhlednost na celou vrstvu, aby překryvy osy a kotoučů neztmavly.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.85),
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
  bool shouldRepaint(_MarkPainter old) => false;
}

/// Potvrzení před nevratnou akcí. Vrací `true` jen po potvrzení.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirm,
  String cancel = 'Zrušit',
  bool destructive = false,
}) async {
  final p = context.palette;
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog.adaptive(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        adaptiveAction(
          dialog,
          label: cancel,
          onPressed: () => Navigator.pop(dialog, false),
        ),
        adaptiveAction(
          dialog,
          label: confirm,
          color: destructive ? p.negative : null,
          strong: true,
          onPressed: () => Navigator.pop(dialog, true),
        ),
      ],
    ),
  );
  return result == true;
}

/// Tlačítko dialogu podle platformy (na iPhonu jako v iOS).
Widget adaptiveAction(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  Color? color,
  bool strong = false,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return CupertinoDialogAction(
      onPressed: onPressed,
      isDefaultAction: strong,
      isDestructiveAction: color != null,
      child: Text(label),
    );
  }
  return TextButton(
    onPressed: onPressed,
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}

/// Krátká zpráva dole na obrazovce.
void showToast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

/// Zpráva s tlačítkem „Vrátit" po smazání.
void showUndo(BuildContext context, String message, VoidCallback onUndo) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'Vrátit', onPressed: onUndo),
        ),
      );

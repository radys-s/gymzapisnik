import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoDialogAction;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'motion.dart';

/// Stránka s velkým nadpisem (iOS): nadpis 34 pt v obsahu, po posunu
/// se objeví malý nadpis v liště a pod ní tenká linka.
class LargeTitlePage extends StatefulWidget {
  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? bottom;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final ScrollController? controller;

  /// Šipka zpět; vypnutá např. u souhrnu hned po tréninku.
  final bool implyLeading;

  const LargeTitlePage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
    this.padding = const EdgeInsets.fromLTRB(
      Space.page,
      Space.s,
      Space.page,
      Space.xxxl,
    ),
    this.controller,
    this.implyLeading = true,
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
      floatingActionButton: widget.floatingActionButton,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          controller: widget.controller,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: widget.implyLeading,
              backgroundColor: p.background,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: collapsed ? 1 : 0,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
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
            child: context.palette.tensor
                // Tensor: štítek datové tabule, ne velký nadpis.
                ? Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: condensedFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.8,
                      color: context.palette.secondaryLabel,
                    ),
                  )
                : Text(title, style: Theme.of(context).textTheme.titleLarge),
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
            shape: p.cardShape(),
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

  /// Svislé odsazení; řádek s vysokým prvkem vpravo (rozbalovací menu
  /// 48 dp) dá 0, ať je stejně vysoký jako ostatní.
  final double verticalPadding;

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
    this.verticalPadding = 10,
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
          padding: EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: verticalPadding,
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
    // Na světlé dlaždici (Studio v tmavém režimu) tmavá ikona.
    child: Icon(
      icon,
      size: size * 0.6,
      color: color.computeLuminance() > 0.179 ? Colors.black : Colors.white,
    ),
  );
}

/// Hlavní akce obrazovky. Aurora ve dne: přechod barev motivu.
/// Ve tmě a ve Studiu plná bílá / černá, na výrazné kartě kontrastní.
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
    final fg = enabled ? p.onCta : p.tertiaryLabel;
    final radius = BorderRadius.circular(p.studio ? 26 : p.controlRadius);
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
            gradient: enabled && p.cta == null ? p.linear : null,
            color: enabled ? p.cta : p.fill,
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
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
                  : p.tensor
                  // Tensor: popisek vlevo úzkým písmem, šipka vpravo.
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg,
                                fontFamily: condensedFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Icon(
                            icon ?? Icons.arrow_forward,
                            color: fg,
                            size: 20,
                          ),
                        ],
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
                                ?.copyWith(
                                  color: fg,
                                  fontStyle: p.pitwall
                                      ? FontStyle.italic
                                      : null,
                                  fontWeight: p.pitwall
                                      ? FontWeight.w900
                                      : null,
                                ),
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
///
/// `vivid` = barevná karta: v Auroře ve dne celá v přechodu motivu,
/// jinak tmavá s měkkou září, která plynule mizí do podkladu. Obsah
/// dostane vlastní motiv, proto barvy čti z `context` uvnitř karty
/// (např. přes [Builder]), ne zvenku.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool vivid;

  /// Velké obrysové číslo v pozadí (Závod: číslo jezdce), jen ozdoba.
  final String? watermark;
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.vivid = false,
    this.watermark,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(Radii.hero);
    if (vivid && p.pitwall) {
      return _RaceHero(padding: padding, watermark: watermark, child: child);
    }
    if (vivid && p.tensor) {
      return _TensorHero(padding: padding, watermark: watermark, child: child);
    }
    if (!vivid) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(color: p.grouped, borderRadius: radius),
        child: child,
      );
    }
    final brightness = Theme.of(context).brightness;
    // Světlý přechod jen u motivů, na kterých je čitelný tmavý text.
    final bright =
        !p.studio &&
        brightness == Brightness.light &&
        p.preset.onGradient == Colors.black;
    final surface = bright ? HeroSurface.bright : HeroSurface.glow;
    final theme = buildTheme(brightness, p.preset, p.look, surface);
    final inner = theme.extension<AppPalette>()!;
    Widget content = Theme(
      data: theme,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: inner.label),
        child: IconTheme.merge(
          data: IconThemeData(color: inner.label),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    DecoratedBox layer(Gradient g, Widget c) => DecoratedBox(
      decoration: BoxDecoration(gradient: g),
      child: c,
    );
    RadialGradient glow(Alignment at, double r, Color c, double a) =>
        RadialGradient(
          center: at,
          radius: r,
          colors: [
            c.withValues(alpha: a),
            c.withValues(alpha: 0),
          ],
        );
    final g = inner.gradient;
    if (bright) {
      // Přechod motivu a světlý odlesk vlevo nahoře („aurora“).
      content = layer(
        LinearGradient(
          colors: g,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        layer(
          glow(const Alignment(-0.9, -1.1), 1.1, Colors.white, 0.45),
          content,
        ),
      );
    } else {
      // Tmavý podklad a záře v sytých tmavých odstínech motivu: barva
      // plynule mizí do podkladu, bílý text zůstane čitelný a světlé
      // barvy (limetka) nezešednou do olivové.
      final base = brightness == Brightness.dark
          ? p.grouped
          : const Color(0xFF111113);
      content = DecoratedBox(
        decoration: BoxDecoration(color: base),
        child: layer(
          // Úhlopříčný přechod nezávisí na poměru stran karty.
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              deepTone(g.last).withValues(alpha: 0.95),
              deepTone(g[1]).withValues(alpha: 0.4),
              deepTone(g[1]).withValues(alpha: 0),
            ],
            stops: const [0, 0.55, 1],
          ),
          layer(
            glow(const Alignment(1.0, 1.25), 1.6, deepTone(g[1]), 0.55),
            content,
          ),
        ),
      );
    }
    return ClipRRect(borderRadius: radius, child: content);
  }
}

/// Hlavní karta Tensoru jako datový displej: černá s jemnou mřížkou,
/// tenká linka, zkosený roh a zelená značka vlevo nahoře. Velké číslo
/// v pozadí je plné a skoro splývá s podkladem.
class _TensorHero extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final String? watermark;
  const _TensorHero({
    required this.child,
    required this.padding,
    this.watermark,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final still = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: p.grouped,
      shape: p.cardShape(),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: const _GridPainter(Color(0xFF141414)),
        child: Stack(
          children: [
            // Zelená rohová značka: tady se rozhoduje.
            Positioned(
              left: 0,
              top: 0,
              child: Container(width: 28, height: 3, color: p.accent),
            ),
            if (watermark != null)
              Positioned(
                right: 44,
                top: 0,
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 0 : 1, end: 0),
                    duration: Motion.slow,
                    curve: Motion.curve,
                    builder: (context, t, child) => Opacity(
                      opacity: 1 - t,
                      child: Transform.translate(
                        offset: Offset(0, 24 * t),
                        child: child,
                      ),
                    ),
                    child: Text(
                      watermark!,
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontFamily: condensedFont,
                        fontSize: 132,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF181818),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Jemná mřížka 22 px jako na měřicím displeji.
class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 22.0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 22.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

/// Hlavní karta Závodu jako karta jezdce: tmavý přechod, červený pruh
/// vlevo a obrysové číslo, které při zobrazení přijede zprava. Paleta
/// zůstává stránková, je dost tmavá i pro text na kartě.
class _RaceHero extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final String? watermark;
  const _RaceHero({required this.child, required this.padding, this.watermark});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final still = MediaQuery.disableAnimationsOf(context);
    return ClipRRect(
      borderRadius: p.cardRadius(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF262636), Color(0xFF1C1C27)],
          ),
          border: Border(left: BorderSide(color: AppPalette.raceRed, width: 4)),
        ),
        child: Stack(
          children: [
            if (watermark != null)
              // Celé číslo uvnitř karty, vlevo od menu (dřív se ořezávalo).
              Positioned(
                right: 48,
                top: 6,
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 0 : 1, end: 0),
                    duration: Motion.slow,
                    curve: Motion.curve,
                    builder: (context, t, child) => Opacity(
                      opacity: 1 - t,
                      child: Transform.translate(
                        offset: Offset(60 * t, 0),
                        child: child,
                      ),
                    ),
                    child: Text(
                      watermark!,
                      // Dekorace: neroste s velikostí písma, jinak se ořízne.
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 128,
                        height: 1,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Pět startovních světel: rozsvítí se jedno po druhém (jednou) a pak
/// zůstanou svítit. Bez animací svítí rovnou.
class StartLights extends StatefulWidget {
  /// Jedno světlo na cvik dnešního tréninku; víc než 8 se nevejde,
  /// přesný počet říká [caption].
  final int count;

  /// Popisek pod světly, např. „5 cviků · ~55 min“.
  final String? caption;
  const StartLights({super.key, this.count = 5, this.caption});

  @override
  State<StartLights> createState() => _StartLightsState();
}

class _StartLightsState extends State<StartLights>
    with SingleTickerProviderStateMixin {
  static const _delay = 0.5;
  static const _step = 0.3;
  int get _n => widget.count.clamp(1, 8);
  double get _total => _delay + _n * _step;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.isDismissed) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(StartLights old) {
    super.didUpdateWidget(old);
    if (old.count == widget.count) return;
    // Jiný den: nový počet světel a start znovu.
    _c.duration = Duration(milliseconds: (_total * 1000).round());
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption;
    if (context.palette.tensor) return _segments(context, caption);
    return Semantics(
      label: caption,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final at = _c.value * _total;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _n; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _Light(on: at >= _delay + i * _step),
                      ),
                  ],
                );
              },
            ),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB8B8C8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on _StartLightsState {
  /// Tensor: jeden dílek na cvik, dílky se postupně rozsvítí zeleně.
  Widget _segments(BuildContext context, String? caption) {
    final p = context.palette;
    return Semantics(
      label: caption,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final at = _c.value * _total;
              return Row(
                children: [
                  for (var i = 0; i < _n; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: _Segment(
                        on:
                            at >=
                            _StartLightsState._delay +
                                i * _StartLightsState._step,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(
                fontFamily: condensedFont,
                color: p.secondaryLabel,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool on;
  const _Segment({required this.on});

  @override
  Widget build(BuildContext context) {
    final a = context.palette.accent;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: on ? a : const Color(0xFF1A1A1A),
        boxShadow: on
            ? [BoxShadow(color: a.withValues(alpha: 0.5), blurRadius: 8)]
            : null,
      ),
    );
  }
}

class _Light extends StatelessWidget {
  final bool on;
  const _Light({required this.on});

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? const Color(0xFFFF1801) : const Color(0xFF2A2A36),
      boxShadow: on
          ? const [BoxShadow(color: Color(0xAAFF1801), blurRadius: 14)]
          : null,
    ),
  );
}

/// Štítek „ŽIVĚ" s tečkou, která třikrát blikne a pak svítí.
class LiveTag extends StatefulWidget {
  final String label;
  const LiveTag({super.key, this.label = 'ŽIVĚ'});

  @override
  State<LiveTag> createState() => _LiveTagState();
}

class _LiveTagState extends State<LiveTag> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _blink = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 1),
  ]).animate(_c);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    _c.repeat(count: 3);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette.positive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _blink,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c,
              boxShadow: [BoxShadow(color: c, blurRadius: 8)],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: c,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Sytý tmavý odstín barvy pro záři pod bílým textem.
Color deepTone(Color c) {
  var h = HSLColor.fromColor(c);
  h = h
      .withLightness((h.lightness * 0.6).clamp(0.22, 0.4))
      .withSaturation(math.min(1, h.saturation * 1.1));
  // Zelené a žluté tóny jsou při stejné světlosti jasnější: ztmavit,
  // dokud bílý text nemá kontrast aspoň 4,5:1 i s průhledností.
  while (h.toColor().computeLuminance() > 0.1 && h.lightness > 0.1) {
    h = h.withLightness(h.lightness - 0.01);
  }
  return h.toColor();
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
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    );
    return Material(
      color: p.grouped,
      shape: p.cardShape(),
      clipBehavior: Clip.antiAlias,
      // Závod: červený pruh vlevo jako na boxové tabuli.
      child: p.pitwall
          ? DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppPalette.raceRed, width: 4),
                ),
              ),
              child: content,
            )
          : content,
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1).toDouble()),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
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

/// Zavře obrazovku jen jednou: druhé rychlé klepnutí během animace by
/// jinak zavřelo i obrazovku pod ní (a s ní neuložené změny).
void popOnce<T extends Object?>(BuildContext context, [T? result]) {
  final route = ModalRoute.of(context);
  if (route != null && !(route.isActive && route.isCurrent)) return;
  Navigator.pop(context, result);
}

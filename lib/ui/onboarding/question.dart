import 'package:flutter/material.dart';

import '../design/ambient.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';

/// Kostra jedné otázky úvodu: lišta s postupem, nadpis, řádek „Proč se
/// ptám“, odpovědi a (u více odpovědí) tlačítko dál.
class QuestionScaffold extends StatelessWidget {
  /// Postup 0–1; `null` skryje lištu (uvítání, odhalení plánu).
  final double? progress;
  final String? step;
  final String? progressLabel;
  final String? title;
  final String? why;
  final Widget child;
  final String? action;
  final VoidCallback? onNext;
  final bool busy;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String skipLabel;
  final Widget? secondary;

  /// Barvy pozadí; každá část úvodu má svoje.
  final Tone tone;

  const QuestionScaffold({
    super.key,
    required this.child,
    this.progress,
    this.step,
    this.progressLabel,
    this.title,
    this.why,
    this.action,
    this.onNext,
    this.busy = false,
    this.onBack,
    this.onSkip,
    this.skipLabel = 'Přeskočit',
    this.secondary,
    this.tone = Tone.training,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: AuroraBackground(
        tone: tone,
        child: SafeArea(child: _body(context, text)),
      ),
    );
  }

  Widget _body(BuildContext context, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: minTap + 4,
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    tooltip: 'Zpět',
                    onPressed: busy ? null : onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else
                  const SizedBox(width: minTap),
                if (progress != null)
                  Expanded(
                    child: _ProgressBar(
                      value: progress!,
                      step: step,
                      progressLabel: progressLabel,
                    ),
                  ),
                if (onSkip != null)
                  TextButton(
                    onPressed: busy ? null : onSkip,
                    child: Text(skipLabel),
                  )
                else
                  const SizedBox(width: minTap),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: Space.l),
              children: [
                if (title case final t?)
                  Reveal(
                    child: Semantics(
                      container: true,
                      header: true,
                      child: Text(t, style: text.headlineLarge),
                    ),
                  ),
                if (why case final w?) ...[
                  const SizedBox(height: Space.m),
                  Reveal(index: 1, child: WhyLine(w)),
                ],
                if (title != null) const SizedBox(height: Space.xxl),
                child,
              ],
            ),
          ),
          if (action case final a?) ...[
            const SizedBox(height: Space.m),
            PrimaryButton(a, busy: busy, onPressed: onNext),
          ],
          ?secondary,
        ],
      ),
    );
  }
}

/// „Proč se ptám“: jedna věta, co aplikace s odpovědí udělá.
class WhyLine extends StatelessWidget {
  final String text;
  const WhyLine(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Proč se ptám: $text',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: p.accent,
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Proč se ptám  ',
                    style: t.labelLarge?.copyWith(
                      color: p.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: t.bodyMedium?.copyWith(color: p.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final String? step;
  final String? progressLabel;
  const _ProgressBar({required this.value, this.step, this.progressLabel});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: p.secondaryLabel, fontFeatures: tabular);
    return Semantics(
      container: true,
      label: step ?? 'Postup ${(value * 100).round()} %',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: p.fill),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: value.clamp(0.0, 1.0)),
                      duration: Motion.of(context, Motion.base),
                      curve: Motion.curve,
                      builder: (_, v, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v,
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: p.linear),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (progressLabel != null) ...[
              const SizedBox(height: Space.xs),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(progressLabel!, style: labelStyle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Velká karta odpovědi: ikona (nebo vlastní [leading]), název, nápověda
/// a značka výběru. Výběr mění jen barvy, nikdy rozměry.
class ChoiceCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String? hint;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  /// Barva ikony a výběru; bez ní barva motivu.
  final Color? color;

  const ChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.hint,
    this.multi = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(p.controlRadius + 2);
    final c = color ?? p.accent;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: !multi,
      label: [label, ?hint].join(', '),
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
              color: c,
              borderRadius: radius,
              child: Material(
                color: Color.lerp(p.grouped, Color.lerp(p.grouped, c, 0.16), t),
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    color: Color.lerp(p.separator, c, t)!,
                    width: 1 + t,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 68),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.l,
                        vertical: Space.m,
                      ),
                      child: Row(
                        children: [
                          if (leading != null || icon != null) ...[
                            SizedBox(
                              width: 44,
                              height: 44,
                              child:
                                  leading ??
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.lerp(
                                            c.withValues(alpha: 0.22),
                                            Color.lerp(c, Colors.white, 0.3),
                                            t,
                                          )!,
                                          Color.lerp(
                                            c.withValues(alpha: 0.10),
                                            c,
                                            t,
                                          )!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        p.controlRadius + 2,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Color.lerp(c, p.onCta, t),
                                    ),
                                  ),
                            ),
                            const SizedBox(width: Space.m),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: text.titleMedium),
                                if (hint case final h?)
                                  Text(
                                    h,
                                    style: text.bodySmall?.copyWith(
                                      color: p.secondaryLabel,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Space.s),
                          _Mark(t: t, multi: multi, color: c),
                        ],
                      ),
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

/// Malá dlaždice odpovědi do mřížky (počet dní, minuty, pohlaví).
class ChoiceTile extends StatelessWidget {
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;
  final String? spoken;

  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
    this.spoken,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: spoken ?? [label, ?hint].join(' '),
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
              color: p.accent,
              borderRadius: BorderRadius.circular(p.controlRadius + 2),
              child: Material(
                color: p.grouped,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(p.controlRadius + 2),
                  side: BorderSide(
                    color: Color.lerp(p.separator, p.accent, t)!,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        for (final g in p.gradient)
                          Color.lerp(p.grouped, g, t)!,
                      ],
                    ),
                  ),
                  child: InkWell(
                    onTap: onTap,
                    child: SizedBox(
                      height: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: text.titleLarge?.copyWith(
                              fontFeatures: tabular,
                              color: Color.lerp(p.label, p.onCta, t),
                            ),
                          ),
                          if (hint case final h?)
                            Text(
                              h,
                              style: text.labelSmall?.copyWith(
                                color: Color.lerp(p.secondaryLabel, p.onCta, t),
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
      ),
    );
  }
}

/// Řada dlaždic stejné šířky; žádná se při výběru nepohne.
class TileRow extends StatelessWidget {
  final List<Widget> children;
  const TileRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, c) in children.indexed) ...[
        if (i > 0) const SizedBox(width: Space.s),
        Expanded(child: c),
      ],
    ],
  );
}

/// Kroužek (jedna odpověď) nebo čtvereček (víc odpovědí), který se při
/// výběru vyplní a ukáže fajfku.
class _Mark extends StatelessWidget {
  final double t;
  final bool multi;
  final Color color;
  const _Mark({required this.t, required this.multi, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Color.lerp(Colors.transparent, color, t),
        shape: multi ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: multi ? BorderRadius.circular(p.controlRadius + 1) : null,
        border: Border.all(
          color: Color.lerp(p.tertiaryLabel, color, t)!,
          width: 1.5,
        ),
      ),
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.5 + 0.5 * t,
          child: Icon(Icons.check_rounded, size: 15, color: p.onCta),
        ),
      ),
    );
  }
}

/// Úroveň zkušenosti jako šest sloupečků; plných je [level] z 6.
class LevelBars extends StatelessWidget {
  final int level;
  final bool selected;
  final Color? color;
  const LevelBars({
    super.key,
    required this.level,
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            AnimatedContainer(
              duration: Motion.of(context, Motion.quick),
              curve: Motion.curve,
              width: 5,
              height: 10.0 + i * 5,
              decoration: BoxDecoration(
                color: i < level
                    ? color ?? p.accent
                    : p.tertiaryLabel.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

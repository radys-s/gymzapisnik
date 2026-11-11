import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';

/// Kostra jedné otázky úvodu: lišta s postupem, nadpis, řádek „Proč se
/// ptám“, odpovědi a (u více odpovědí) tlačítko dál.
class QuestionScaffold extends StatelessWidget {
  /// Postup 0–1; `null` skryje lištu (uvítání, odhalení plánu).
  final double? progress;
  final String? step;
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

  const QuestionScaffold({
    super.key,
    required this.child,
    this.progress,
    this.step,
    this.title,
    this.why,
    this.action,
    this.onNext,
    this.busy = false,
    this.onBack,
    this.onSkip,
    this.skipLabel = 'Přeskočit',
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.xl,
          ),
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
                    Expanded(
                      child: progress == null
                          ? const SizedBox.shrink()
                          : _ProgressBar(value: progress!, step: step),
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
        ),
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
  const _ProgressBar({required this.value, this.step});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: step ?? 'Postup ${(value * 100).round()} %',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s),
        child: ClipRRect(
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

  const ChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.hint,
    this.multi = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(p.controlRadius + 2);
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
            builder: (context, t, _) => Material(
              color: Color.lerp(p.grouped, p.accent.withValues(alpha: 0.12), t),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: Color.lerp(p.separator, p.accent, t)!,
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
                                    color: Color.lerp(p.fill, p.accent, t),
                                    borderRadius: BorderRadius.circular(
                                      p.controlRadius + 2,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Color.lerp(p.accent, p.onCta, t),
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
                        _Mark(t: t, multi: multi),
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
            builder: (context, t, _) => Material(
              color: Color.lerp(p.grouped, p.accent, t),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(p.controlRadius + 2),
                side: BorderSide(color: Color.lerp(p.separator, p.accent, t)!),
              ),
              clipBehavior: Clip.antiAlias,
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
  const _Mark({required this.t, required this.multi});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Color.lerp(Colors.transparent, p.accent, t),
        shape: multi ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: multi ? BorderRadius.circular(p.controlRadius + 1) : null,
        border: Border.all(
          color: Color.lerp(p.tertiaryLabel, p.accent, t)!,
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
  const LevelBars({super.key, required this.level, this.selected = false});

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
                    ? p.accent
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

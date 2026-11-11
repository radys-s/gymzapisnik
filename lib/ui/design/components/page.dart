part of '../components.dart';

// Stránka s velkým nadpisem a seskupené řádky.

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
            // Štítek datové tabule, ne velký nadpis.
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontFamily: condensedFont,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.8,
                color: context.palette.secondaryLabel,
              ),
            ),
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/parse.dart';
import '../../domain/bodyweight.dart';
import '../../domain/measurement.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../widgets/chart_axis.dart';

/// [BodyPart.label] is also a stored value, so keep the Czech source and add
/// the English display text here.
String bodyPartLabel(BodyPart part) => switch (part) {
  BodyPart.waist => tr(part.label, 'Waist'),
  BodyPart.chest => tr(part.label, 'Chest'),
  BodyPart.arm => tr(part.label, 'Arm'),
  BodyPart.forearm => tr(part.label, 'Forearm'),
  BodyPart.thigh => tr(part.label, 'Thigh'),
  BodyPart.calf => tr(part.label, 'Calf'),
  BodyPart.hips => tr(part.label, 'Hips'),
  BodyPart.neck => tr(part.label, 'Neck'),
};

/// Dialog „Zapsat váhu". Vrací `true`, když se váha uložila.
Future<bool> addBodyweightDialog(BuildContext context, AppState state) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _WeightDialog(state),
  );
  return saved == true;
}

class _WeightDialog extends StatefulWidget {
  final AppState state;
  const _WeightDialog(this.state);

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  late final controller = TextEditingController(
    text: widget.state.bodyweights.isEmpty
        ? ''
        : formatKg(widget.state.bodyweights.first.kg),
  );
  String? error;
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (busy) return;
    final kg = parseNum(controller.text);
    setState(() => busy = true);
    try {
      if (kg == null || !await widget.state.addBodyweight(kg)) {
        if (mounted) {
          setState(() {
            error = tr(
              'Zadej váhu mezi 20 a 400 kg.',
              'Enter a weight between 20 and 400 kg.',
            );
          });
        }
        return;
      }
      if (mounted) popOnce(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = tr('Váhu se nepodařilo uložit.', 'Could not save weight.');
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr('Zapsat váhu', 'Log weight')),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: tr('Váha (kg)', 'Weight (kg)'),
        errorText: error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(tr('Zrušit', 'Cancel')),
      ),
      FilledButton(
        onPressed: busy ? null : _save,
        child: Text(tr('Uložit', 'Save')),
      ),
    ],
  );
}

/// Dialog „Přidat míru". Vrací `true`, když se míra uložila.
Future<bool> addMeasurementDialog(BuildContext context, AppState state) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _MeasurementDialog(state),
  );
  return saved == true;
}

class _MeasurementDialog extends StatefulWidget {
  final AppState state;
  const _MeasurementDialog(this.state);

  @override
  State<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<_MeasurementDialog> {
  BodyPart _part = BodyPart.waist;
  late final controller = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (busy) return;
    final cm = parseNum(controller.text);
    setState(() => busy = true);
    try {
      if (cm == null || !await widget.state.addMeasurement(_part, cm)) {
        if (mounted) {
          showToast(
            context,
            tr(
              'Zadej míru mezi 10 a 250 cm.',
              'Enter a measurement between 10 and 250 cm.',
            ),
          );
        }
        return;
      }
      if (mounted) popOnce(context, true);
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          tr('Míru se nepodařilo uložit.', 'Could not save measurement.'),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr('Přidat míru', 'Add measurement')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<BodyPart>(
          value: _part,
          isExpanded: true,
          items: [
            for (final part in BodyPart.values)
              DropdownMenuItem(value: part, child: Text(bodyPartLabel(part))),
          ],
          onChanged: busy
              ? null
              : (part) {
                  if (part != null) setState(() => _part = part);
                },
        ),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: tr('Obvod (cm)', 'Circumference (cm)'),
          ),
          onSubmitted: (_) => _save(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(tr('Zrušit', 'Cancel')),
      ),
      FilledButton(
        onPressed: busy ? null : _save,
        child: Text(tr('Uložit', 'Save')),
      ),
    ],
  );
}

/// Karta na úvodní obrazovce: poslední váha, změna za měsíc, zápis jedním
/// klepnutím. Žádné cíle ani doporučení hubnutí.
class BodyweightCard extends StatelessWidget {
  final AppState state;
  const BodyweightCard(this.state, {super.key});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: state.on.resting, builder: _card);

  Widget _card(BuildContext context, Widget? _) {
    final scheme = Theme.of(context).colorScheme;
    final list = state.bodyweights;
    final change = changeOver(list);
    final sign = change == null
        ? ''
        : (change > 0 ? '+' : (change < 0 ? '−' : '±'));
    final changeText = change == null
        ? ''
        : tr(
            ' · $sign${formatKg(change.abs())} kg za měsíc',
            ' · $sign${formatKg(change.abs())} kg per month',
          );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text(
          list.isEmpty
              ? tr('Tělesná váha', 'Body weight')
              : '${formatKg(list.first.kg)} kg',
        ),
        subtitle: Text(
          list.isEmpty
              ? tr(
                  'Zapiš si váhu a sleduj vývoj',
                  'Log your weight to track changes',
                )
              : '${formatDate(list.first.date)}$changeText',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: tr('Zapsat váhu', 'Log weight'),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => addBodyweightDialog(context, state),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BodyweightPage(state)),
        ),
      ),
    );
  }
}

class BodyweightPage extends StatelessWidget {
  final AppState state;
  const BodyweightPage(this.state, {super.key});

  Future<void> _remove(BuildContext context, BodyWeight entry) async {
    final messenger = ScaffoldMessenger.of(context);
    await state.removeBodyweight(entry.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Smazáno: ${formatKg(entry.kg)} kg',
              'Deleted: ${formatKg(entry.kg)} kg',
            ),
          ),
          action: SnackBarAction(
            label: tr('Vrátit', 'Undo'),
            onPressed: () => state.restoreBodyweight(entry),
          ),
        ),
      );
  }

  Future<void> _removeMeasurement(
    BuildContext context,
    Measurement entry,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await state.removeMeasurement(entry.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Smazáno: ${formatKg(entry.cm)} cm',
              'Deleted: ${formatKg(entry.cm)} cm',
            ),
          ),
          action: SnackBarAction(
            label: tr('Vrátit', 'Undo'),
            onPressed: () => state.restoreMeasurement(entry),
          ),
        ),
      );
  }

  Widget _measurementRow(
    BuildContext context,
    BodyPart part,
    List<Measurement> entries,
  ) {
    final latest = entries.first;
    final change = measurementChange(entries, part);
    final sign = change == null
        ? ''
        : (change > 0 ? '+' : (change < 0 ? '−' : '±'));
    return GroupedRow(
      title: bodyPartLabel(part),
      value: '${formatKg(latest.cm)} cm',
      subtitle: change == null
          ? formatDate(latest.date)
          : tr(
              '$sign${formatKg(change.abs())} cm za 30 dní',
              '$sign${formatKg(change.abs())} cm in 30 days',
            ),
      onTap: () => _measurementHistory(context, part),
    );
  }

  void _measurementHistory(BuildContext context, BodyPart part) {
    final state = this.state;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bodyPartLabel(part),
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              const SizedBox(height: Space.s),
              ListenableBuilder(
                listenable: state.on.resting,
                builder: (context, _) {
                  final entries = [
                    for (final m in state.measurements)
                      if (m.part == part) m,
                  ];
                  if (entries.isEmpty) {
                    return Text(
                      tr('Zatím žádné záznamy.', 'No entries yet.'),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: context.palette.secondaryLabel),
                    );
                  }
                  return SingleChildScrollView(
                    child: GroupedSection(
                      children: [
                        for (final m in entries)
                          GroupedRow(
                            title: formatDate(m.date),
                            value: '${formatKg(m.cm)} cm',
                            chevron: false,
                            trailing: IconButton(
                              tooltip: tr('Smazat záznam', 'Delete entry'),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeMeasurement(context, m),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _measurementWidgets(BuildContext context) {
    final byPart = <BodyPart, List<Measurement>>{};
    for (final m in state.measurements) {
      (byPart[m.part] ??= []).add(m);
    }
    final parts = [
      for (final part in BodyPart.values)
        if (byPart[part] != null) part,
    ];
    return [
      SectionHeader(tr('Míry', 'Measurements')),
      if (parts.isEmpty)
        Text(
          tr(
            'Měř pas, paže nebo hrudník jednou za 2–4 týdny. Váha neřekne všechno.',
            'Measure your waist, arm or chest every 2–4 weeks. Weight does not tell the whole story.',
          ),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.palette.secondaryLabel),
        )
      else
        GroupedSection(
          children: [
            for (final part in parts)
              _measurementRow(context, part, byPart[part]!),
          ],
        ),
      SecondaryButton(
        tr('Přidat míru', 'Add measurement'),
        icon: Icons.straighten_rounded,
        onPressed: () => addMeasurementDialog(context, state),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
    builder: (context, _) {
      final list = state.bodyweights;
      return LargeTitlePage(
        title: tr('Tělesná váha', 'Body weight'),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => addBodyweightDialog(context, state),
          icon: const Icon(Icons.add),
          label: Text(tr('Zapsat váhu', 'Log weight')),
        ),
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 96),
        children: [
          if (list.isEmpty)
            EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: tr('Zatím žádná váha', 'No weight yet'),
              message: tr(
                'Zapiš si váhu a uvidíš, jak se mění.',
                'Log your weight to see how it changes.',
              ),
            )
          else ...[
            if (list.length >= 2)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (list.length >= 3) ...[
                      Text(
                        tr(
                          'Průměr za 7 dní: ${formatKg(double.parse(trailingAverage(list.reversed.toList()).last.toStringAsFixed(1)))} kg',
                          '7-day average: ${formatKg(double.parse(trailingAverage(list.reversed.toList()).last.toStringAsFixed(1)))} kg',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        tr(
                          'Čára je průměr, tečky jednotlivá vážení. '
                              'Váha během dne kolísá, průměr ukáže skutečný směr.',
                          'The line is the average, dots are individual weigh-ins. '
                              'Weight fluctuates during the day; the average shows the real trend.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.palette.secondaryLabel),
                      ),
                      const SizedBox(height: Space.l),
                    ],
                    SizedBox(
                      height: 200,
                      child: _Chart(list.reversed.toList()),
                    ),
                  ],
                ),
              ),
            if (list.length >= 2) const SizedBox(height: Space.xxl),
            GroupedSection(
              header: tr('Záznamy', 'Entries'),
              children: [
                for (final b in list)
                  GroupedRow(
                    title: '${formatKg(b.kg)} kg',
                    subtitle: formatDate(b.date),
                    chevron: false,
                    trailing: IconButton(
                      tooltip: tr('Smazat záznam', 'Delete entry'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(context, b),
                    ),
                  ),
              ],
            ),
          ],
          ..._measurementWidgets(context),
        ],
      );
    },
  );
}

class _Chart extends StatelessWidget {
  final List<BodyWeight> points;
  const _Chart(this.points);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = [for (final p in points) p.kg];
    final smooth = points.length >= 3;
    final average = trailingAverage(points);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.2).clamp(1.0, 10.0);
    return Semantics(
      container: true,
      label: tr(
        'Graf váhy, ${points.length} záznamů, od ${formatKg(points.first.kg)} '
            'do ${formatKg(points.last.kg)} kg',
        'Weight chart, ${points.length} entries, from ${formatKg(points.first.kg)} '
            'to ${formatKg(points.last.kg)} kg',
      ),
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i != value || !showDateLabel(i, points.length)) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date.toLocal();
                  return axisLabel(
                    meta,
                    '${d.day}. ${d.month}.',
                    const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => valueAxisLabel(
                  value,
                  meta,
                  formatKg(value.roundToDouble()),
                  const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
          lineBarsData: [
            // Jednotlivá vážení jen jako tečky; u dvou záznamů ještě bez průměru.
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].kg),
              ],
              color: smooth
                  ? scheme.primary.withValues(alpha: 0.45)
                  : scheme.primary,
              barWidth: smooth ? 0 : 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: !smooth,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
            if (smooth)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), average[i]),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: scheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

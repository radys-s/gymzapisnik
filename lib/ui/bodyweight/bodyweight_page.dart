import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/bodyweight.dart';
import '../../state/app_state.dart';
import '../design/components.dart';

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
        if (mounted) setState(() => error = 'Zadej váhu mezi 20 a 400 kg.');
        return;
      }
      if (mounted) popOnce(context, true);
    } catch (_) {
      if (mounted) setState(() => error = 'Váhu se nepodařilo uložit.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Zapsat váhu'),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: 'Váha (kg)', errorText: error),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Zrušit'),
      ),
      FilledButton(onPressed: busy ? null : _save, child: const Text('Uložit')),
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
      ListenableBuilder(listenable: state, builder: _card);

  Widget _card(BuildContext context, Widget? _) {
    final scheme = Theme.of(context).colorScheme;
    final list = state.bodyweights;
    final change = changeOver(list);
    final sign = change == null
        ? ''
        : (change > 0 ? '+' : (change < 0 ? '−' : '±'));
    final changeText = change == null
        ? ''
        : ' · $sign${formatKg(change.abs())} kg za měsíc';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text(
          list.isEmpty ? 'Tělesná váha' : '${formatKg(list.first.kg)} kg',
        ),
        subtitle: Text(
          list.isEmpty
              ? 'Zapiš si váhu a sleduj vývoj'
              : '${formatDate(list.first.date)}$changeText',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: 'Zapsat váhu',
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final list = state.bodyweights;
      return Scaffold(
        appBar: AppBar(title: const Text('Tělesná váha')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => addBodyweightDialog(context, state),
          icon: const Icon(Icons.add),
          label: const Text('Zapsat váhu'),
        ),
        body: list.isEmpty
            ? const Center(child: Text('Zatím žádná váha.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (list.length >= 2) ...[
                    SizedBox(
                      height: 200,
                      child: _Chart(list.reversed.toList()),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final b in list)
                    ListTile(
                      title: Text('${formatKg(b.kg)} kg'),
                      subtitle: Text(formatDate(b.date)),
                      trailing: IconButton(
                        tooltip: 'Smazat záznam',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.removeBodyweight(b.id),
                      ),
                    ),
                ],
              ),
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
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.2).clamp(1.0, 10.0);
    return Semantics(
      container: true,
      label:
          'Graf váhy, ${points.length} záznamů, od ${formatKg(points.first.kg)} '
          'do ${formatKg(points.last.kg)} kg',
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
                  if (i != value || i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final step = (points.length / 4).ceil();
                  if (i != points.length - 1 && i % step != 0) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date.toLocal();
                  return Text(
                    '${d.day}. ${d.month}.',
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  formatKg(value.roundToDouble()),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].kg),
              ],
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../coach/plates.dart';
import '../../core/format.dart';
import '../../core/parse.dart';
import '../design/tokens.dart';

/// Kolik kotoučů dát na každou stranu osy.
Future<void> showPlates(BuildContext context, double weight) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PlatesSheet(initial: weight),
    );

class PlatesSheet extends StatefulWidget {
  final double initial;
  const PlatesSheet({super.key, required this.initial});

  @override
  State<PlatesSheet> createState() => _PlatesSheetState();
}

class _PlatesSheetState extends State<PlatesSheet> {
  late final controller = TextEditingController(
    text: widget.initial > 0 ? formatKg(widget.initial) : '',
  );
  double bar = barWeights.first;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final total = parseNum(controller.text) ?? 0;
    final load = platesFor(total, bar: bar);
    final String result;
    if (total <= 0) {
      result = 'Zadej celkovou váhu.';
    } else if (total < bar) {
      result = 'Lehčí než samotná osa (${formatKg(bar)} kg).';
    } else if (load.perSide.isEmpty) {
      result = 'Jen osa, bez kotoučů.';
    } else {
      result = 'Na každou stranu: ${load.perSide.map(formatKg).join(' + ')} kg';
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.page,
        0,
        Space.page,
        Space.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kotouče na činku', style: text.titleLarge),
          const SizedBox(height: Space.m),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Celková váha včetně osy',
              suffixText: 'kg',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.m),
          Text('Osa', style: text.labelLarge),
          const SizedBox(height: Space.xs),
          SegmentedButton<double>(
            segments: [
              for (final b in barWeights)
                ButtonSegment(value: b, label: Text('${formatKg(b)} kg')),
            ],
            selected: {bar},
            onSelectionChanged: (v) => setState(() => bar = v.first),
          ),
          const SizedBox(height: Space.l),
          Semantics(
            liveRegion: true,
            child: Text(result, style: text.titleMedium),
          ),
          if (load.perSide.isNotEmpty) ...[
            const SizedBox(height: Space.m),
            ExcludeSemantics(child: _BarPicture(plates: load.perSide)),
          ],
          if (load.missing > 0 && total > bar) ...[
            const SizedBox(height: Space.s),
            Text(
              'Z běžných kotoučů nejde přesně; chybí ${formatKg(load.missing)} kg.',
              style: text.bodySmall?.copyWith(color: p.negative),
            ),
          ],
        ],
      ),
    );
  }
}

/// Jedna strana osy s kotouči (větší = vyšší).
class _BarPicture extends StatelessWidget {
  final List<double> plates;
  const _BarPicture({required this.plates});

  static final _colors = <double, Color>{
    25.0: Color(0xFFE5383B),
    20.0: Color(0xFF1E6FD9),
    15.0: Color(0xFFF2C14E),
    10.0: Color(0xFF2E9E4F),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          Container(width: 28, height: 10, color: p.tertiaryLabel),
          Container(width: 8, height: 30, color: p.secondaryLabel),
          for (final w in plates)
            Container(
              width: w >= 10 ? 18 : 12,
              height: 30 + 66 * (w / 25).clamp(0.2, 1.0),
              margin: const EdgeInsets.only(left: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _colors[w] ?? p.secondaryLabel,
                borderRadius: BorderRadius.circular(3),
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  formatKg(w),
                  style: TextStyle(
                    fontSize: 10,
                    color: w == 15 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Expanded(child: Container(height: 10, color: p.tertiaryLabel)),
        ],
      ),
    );
  }
}

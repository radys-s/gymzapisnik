import 'package:flutter/material.dart';

import '../../core/i18n.dart';

import '../design/motion.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Smazání všech dat schválně není na jedno klepnutí: nejdřív upozornění,
/// pak potvrzení zaškrtnutím a nakonec podržení tlačítka.
Future<bool> confirmWipe(BuildContext context) async {
  final first = await confirmAction(
    context,
    title: tr('Smazat všechna data?', 'Delete all data?'),
    message: tr(
      'Tréninky, vlastní cviky, strava i nastavení v tomto zařízení se '
          'trvale smažou a nejdou vrátit. Nejdřív si ulož zálohu do souboru.',
      'Workouts, custom exercises, food and settings on this device will '
          'be permanently deleted and cannot be restored. Back up to a file first.',
    ),
    confirm: tr('Pokračovat', 'Continue'),
    destructive: true,
  );
  if (!first || !context.mounted) return false;
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const _HoldToWipe(),
  );
  return result == true;
}

class _HoldToWipe extends StatefulWidget {
  const _HoldToWipe();

  @override
  State<_HoldToWipe> createState() => _HoldToWipeState();
}

class _HoldToWipeState extends State<_HoldToWipe>
    with SingleTickerProviderStateMixin {
  static const hold = Duration(seconds: 3);
  bool understood = false;
  late final _progress = AnimationController(vsync: this, duration: hold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.pop(context, true);
      }
    });

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _start() {
    if (understood) _progress.forward();
  }

  void _release() {
    if (!_progress.isCompleted) {
      _progress.animateBack(0, duration: Motion.of(context, Motion.quick));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(tr('Poslední krok', 'Last step')),
      // Pevná šířka: zaškrtávací řádek ani výplň neumí vnitřní rozměry.
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: understood,
              onChanged: (v) {
                setState(() => understood = v ?? false);
                if (!understood) _progress.value = 0;
              },
              title: Text(
                tr(
                  'Rozumím, že se data nedají vrátit',
                  'I understand data cannot be restored',
                ),
              ),
            ),
            const SizedBox(height: Space.m),
            Semantics(
              button: true,
              enabled: understood,
              label: tr(
                'Podrž 3 sekundy pro smazání všech dat',
                'Hold for 3 seconds to delete all data',
              ),
              // Čtečka obrazovky nemá jak držet: dlouhé stisknutí potvrdí hned.
              onLongPress: understood
                  ? () => Navigator.pop(context, true)
                  : null,
              excludeSemantics: true,
              child: Listener(
                onPointerDown: (_) => _start(),
                onPointerUp: (_) => _release(),
                onPointerCancel: (_) => _release(),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, _) => Container(
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: understood
                          ? p.negative.withValues(alpha: 0.18)
                          : p.fill,
                      borderRadius: BorderRadius.circular(Radii.control),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress.value,
                          child: ColoredBox(color: p.negative),
                        ),
                        Center(
                          child: Text(
                            _progress.value > 0
                                ? tr('Drž dál…', 'Keep holding…')
                                : tr(
                                    'Podrž 3 s pro smazání',
                                    'Hold 3 s to delete',
                                  ),
                            style: text.titleSmall?.copyWith(
                              color: understood ? p.label : p.tertiaryLabel,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('Zrušit', 'Cancel')),
        ),
      ],
    );
  }
}

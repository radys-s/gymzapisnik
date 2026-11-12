import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Vydání, ke kterému patří novinky níže. Při nových novinkách zvyš,
/// ať se okno ukáže jednou každému, kdo je ještě neviděl.
const whatsNewRelease = '1.6';

/// Novinky aktuálního vydání: ikona, nadpis, jedna věta.
const whatsNewItems = <(IconData, String, String)>[
  (
    Icons.home_outlined,
    'Nový Domov',
    'Nahoře jídlo dne s rychlým přidáním, pod ním dnešní trénink '
        'a kolik sérií má která partie tento týden.',
  ),
  (
    Icons.fact_check_outlined,
    'Kontrola rutiny',
    'Editor programu ukáže, co v rutině chybí, a navržený cvik '
        'přidá jedním klepnutím.',
  ),
  (
    Icons.store_outlined,
    'Moje posilovna',
    'Odškrtni stroje, které tvoje posilovna nemá, a plán je nebude '
        'nabízet.',
  ),
  (
    Icons.check_circle_outline,
    'Klidnější zápis',
    'Potvrzení série bez rušení uprostřed tréninku. Rekordy oslavíš '
        'v souhrnu, který se odhaluje postupně.',
  ),
  (
    Icons.save_outlined,
    'Bezpečnější data',
    'Připomínka zálohy na Domově a v Nastavení Diagnostika chyb '
        'pro hlášení problémů.',
  ),
];

/// Seznam novinek (sdílí okno po aktualizaci i stránka v Nastavení).
class WhatsNewList extends StatelessWidget {
  const WhatsNewList({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (icon, title, body) in whatsNewItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: p.accent),
                const SizedBox(width: Space.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: text.bodyMedium?.copyWith(
                          color: p.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ukáže novinky, pokud je uživatel ještě neviděl (jednou za vydání).
Future<void> showWhatsNewOnce(BuildContext context, AppState state) async {
  if (state.profile.seenVersion == whatsNewRelease) return;
  final text = Theme.of(context).textTheme;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Co je nového',
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.l),
            const WhatsNewList(),
            const SizedBox(height: Space.xl),
            PrimaryButton('Pokračovat', onPressed: () => Navigator.pop(sheet)),
          ],
        ),
      ),
    ),
  );
  // I když se uložení nepovede, okno se tentokrát už znovu neukáže.
  try {
    await state.markVersionSeen(whatsNewRelease);
  } catch (e) {
    debugPrint('Novinky se nepodařilo označit: $e');
  }
}

/// Novinky k dohledání v Nastavení.
class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) => const LargeTitlePage(
    title: 'Novinky',
    children: [Panel(child: WhatsNewList())],
  );
}

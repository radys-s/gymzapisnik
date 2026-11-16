import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Vydání, ke kterému patří novinky níže. Při nových novinkách zvyš,
/// ať se okno ukáže jednou každému, kdo je ještě neviděl.
const whatsNewRelease = '1.7';

/// Novinky aktuálního vydání: ikona, nadpis, jedna věta.
const whatsNewItems = <(IconData, String, String)>[
  (
    Icons.palette_outlined,
    'Nový vzhled',
    'Tmavý podklad s barvami: trénink zelený, strava oranžová, pokrok '
        'fialový. Pozadí se pomalu hýbe a hlavní tlačítko se občas zaleskne.',
  ),
  (
    Icons.auto_awesome_outlined,
    'Nové logo',
    'Kruh postupu s činkou. Stejná značka je na ikoně, při spuštění '
        'i v aplikaci.',
  ),
  (
    Icons.home_outlined,
    'Domov na jednu obrazovku',
    'Dnešní trénink, jídlo dne a cíl týdne se vejdou pod sebe bez '
        'posouvání.',
  ),
  (
    Icons.rule_rounded,
    'Den programu po svém',
    'Při přidání dne si rovnou vybereš: nechat si cviky navrhnout podle '
        'partií, nebo je vybrat sám z celého seznamu.',
  ),
  (
    Icons.bolt_outlined,
    'Kratší úvod',
    'Podmínky a věk hned na začátku, pak pět otázek. Rok narození už '
        'nezadáváš.',
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

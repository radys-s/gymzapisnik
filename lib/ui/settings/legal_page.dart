import 'package:flutter/material.dart';

/// Podmínky používání a zásady soukromí (beta verze).
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static const sections = <(String, String)>[
    (
      'Co aplikace je',
      'Gym zápisník je zápisník tréninků s jednoduchým koučem. Je to beta '
          'verze: může obsahovat chyby a měnit se. Nenahrazuje trenéra ani '
          'lékaře. Cvič v rozsahu, který zvládáš, a při bolesti nebo '
          'zdravotních potížích se poraď s lékařem.',
    ),
    (
      'Věk',
      'Aplikaci smí používat každý od 18 let. Mladší jen se souhlasem '
          'zákonného zástupce. Pro mladší 18 let aplikace nenabízí cíle '
          'hubnutí ani omezování jídla.',
    ),
    (
      'Jaká data a kde',
      'Tréninky, cviky, tělesná váha a nastavení se ukládají jen v tomto '
          'zařízení. Aplikace nemá účet, nic nenahrává na server a neobsahuje '
          'reklamy ani sledování. Pokud v telefonu povolíš oznámení, '
          'připomínky se plánují lokálně v zařízení.',
    ),
    (
      'Záloha a smazání',
      'Protože data nejsou nikde jinde, ulož si zálohu do souboru '
          '(Nastavení → Uložit zálohu). Smazáním dat prohlížeče, odinstalací '
          'nebo vyčištěním úložiště data zmizí. Všechno v zařízení smažeš '
          'v Nastavení → Smazat všechna data.',
    ),
    (
      'Zodpovědnost',
      'Aplikace se poskytuje tak, jak je, bez záruky. Za zranění, ztrátu dat '
          'ani jiné škody při používání autor neručí, v rozsahu, který '
          'dovoluje zákon.',
    ),
    (
      'Změny a kontakt',
      'Podmínky se mohou změnit; o podstatné změně se dozvíš v aplikaci. '
          'Dotazy a zpětnou vazbu pošli přes Nastavení → Napsat zpětnou vazbu.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Podmínky a soukromí')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final (title, body) in sections) ...[
            const SizedBox(height: 12),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(body),
          ],
        ],
      ),
    );
  }
}

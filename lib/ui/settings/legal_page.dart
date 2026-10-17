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
      'Tréninky, cviky, tělesná váha, výživový deník a nastavení se ukládají '
          'jen v tomto zařízení. Aplikace nemá účet ani cloudovou synchronizaci. '
          'Dotazy na Open Food Facts a AI popisujeme níže. Neobsahuje '
          'reklamy ani sledování. Pokud v telefonu povolíš oznámení, '
          'připomínky se plánují lokálně v zařízení.',
    ),
    (
      'Čárové kódy a Open Food Facts',
      'Když hledáš produkt podle čárového kódu, aplikace odešle jen ten kód '
          'a své označení (název a verzi) do veřejné databáze Open Food Facts '
          '(openfoodfacts.org); ta ho přijme jako každý jiný dotaz včetně '
          'IP adresy. Bez hledání se nic neodesílá a deník funguje offline. '
          'Údaje databáze jsou pod licencí ODbL, vytvořili je dobrovolníci '
          'a mohou být nepřesné: před uložením je zkontroluj. Výživová data '
          'jsou orientační a nejsou zdravotním doporučením.',
    ),
    (
      'AI: lednička a návrhy jídel',
      'Funkce „Co mám v ledničce“ odešle fotku nebo seznam potravin '
          '(a u návrhu jídel i dnešní součet bílkovin, u dospělých i energie, '
          'a zda dnes trénuješ) přes server aplikace na Cloudflare do služby '
          'Cloudflare Workers AI (otevřený model Mistral Small 3.1). Fotka ani '
          'texty se neukládají ani nelogují. Server si pamatuje jen počet '
          'dotazů za den podle náhodného ID instalace (kvůli limitu), dva dny. '
          'AI se může splést v rozpoznání i v hodnotách; návrhy jsou jen '
          'inspirace, ne výživové ani zdravotní doporučení. Bez použití této '
          'funkce se nic neodesílá.',
    ),
    (
      'Záloha a smazání',
      'Protože data nejsou nikde jinde, ulož si zálohu do souboru '
          '(Nastavení, řádek Uložit zálohu). Smazáním dat prohlížeče, odinstalací '
          'nebo vyčištěním úložiště data zmizí. Všechno v zařízení smažeš '
          'v Nastavení, řádek Smazat všechna data.',
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
          'Dotazy a zpětnou vazbu pošli v Nastavení, řádek Napsat zpětnou vazbu.',
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

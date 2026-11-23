import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Podmínky používání a zásady soukromí (beta verze).
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static List<(String, String)> sections() => [
    (
      tr('Co aplikace je', 'What the app is'),
      tr(
        'Gym zápisník je zápisník tréninků s jednoduchým koučem. Je to beta '
            'verze: může obsahovat chyby a měnit se. Nenahrazuje trenéra ani '
            'lékaře. Cvič v rozsahu, který zvládáš, a při bolesti nebo '
            'zdravotních potížích se poraď s lékařem.',
        'Gym Log is a workout log with a simple coach. It is a beta: it may '
            'have bugs and change over time. It does not replace a trainer or a '
            'doctor. Train within your abilities and see a doctor if you feel '
            'pain or have health problems.',
      ),
    ),
    (
      tr('Věk', 'Age'),
      tr(
        'Aplikaci smí používat každý od 18 let. Mladší jen se souhlasem '
            'zákonného zástupce. Pro mladší 18 let aplikace nenabízí cíle '
            'hubnutí ani omezování jídla.',
        'You must be 18 or older to use the app. Younger users need a '
            'parent or guardian’s consent. The app does not offer weight-loss '
            'goals or food restriction to anyone under 18.',
      ),
    ),
    (
      tr('Jaká data a kde', 'What data and where'),
      tr(
        'Tréninky, cviky, tělesná váha, výživový deník a nastavení se ukládají '
            'jen v tomto zařízení. Aplikace nemá účet ani cloudovou synchronizaci. '
            'Dotazy na Open Food Facts a AI popisujeme níže. Neobsahuje '
            'reklamy ani sledování. Pokud v telefonu povolíš oznámení, '
            'připomínky se plánují lokálně v zařízení.',
        'Workouts, exercises, body weight, food diary and settings stay on '
            'this device only. There is no account or cloud sync. Requests to '
            'Open Food Facts and AI are described below. There are no ads or '
            'trackers. If you allow notifications, reminders are scheduled '
            'locally on your device.',
      ),
    ),
    (
      tr('Čárové kódy a Open Food Facts', 'Barcodes and Open Food Facts'),
      tr(
        'Když hledáš produkt podle čárového kódu, aplikace odešle jen ten kód '
            'a své označení (název a verzi) do veřejné databáze Open Food Facts '
            '(openfoodfacts.org); ta ho přijme jako každý jiný dotaz včetně '
            'IP adresy. Bez hledání se nic neodesílá a deník funguje offline. '
            'Údaje databáze jsou pod licencí ODbL, vytvořili je dobrovolníci '
            'a mohou být nepřesné: před uložením je zkontroluj. Výživová data '
            'jsou orientační a nejsou zdravotním doporučením.',
        'When you look up a barcode, the app sends only that code and its '
            'own identifier (name and version) to the public Open Food Facts '
            'database (openfoodfacts.org), which treats it like any other '
            'request, including your IP address. Without a search, nothing is '
            'sent and the diary works offline. Database entries are under the '
            'ODbL licence, created by volunteers, and may be inaccurate: check '
            'them before saving. Nutrition data is approximate and is not health '
            'advice.',
      ),
    ),
    (
      tr('AI: lednička a návrhy jídel', 'AI: fridge and meal ideas'),
      tr(
        'Funkce „Co mám v ledničce“ odešle fotku nebo seznam potravin '
            '(a u návrhu jídel i dnešní součet bílkovin, u dospělých i energie, '
            'a zda dnes trénuješ) přes server aplikace na Cloudflare do služby '
            'Cloudflare Workers AI (otevřený model Mistral Small 3.1). Fotka ani '
            'texty se neukládají ani nelogují. Server si pamatuje jen počet '
            'dotazů za den podle náhodného ID instalace (kvůli limitu), dva dny. '
            'AI se může splést v rozpoznání i v hodnotách; návrhy jsou jen '
            'inspirace, ne výživové ani zdravotní doporučení. Bez použití této '
            'funkce se nic neodesílá.',
        'The "What is in my fridge" feature sends a photo or food list '
            '(for meal ideas also today’s protein total, calories for adults, '
            'and whether you trained today) through the app server on Cloudflare '
            'to Cloudflare Workers AI (open model Mistral Small 3.1). Photos and '
            'text are neither stored nor logged. The server only remembers the '
            'daily request count against a random install ID (for rate limits) '
            'for two days. AI can get recognition and values wrong; suggestions '
            'are inspiration, not nutrition or health advice. Nothing is sent '
            'unless you use this feature.',
      ),
    ),
    (
      tr('AI: fotka stroje', 'AI: machine photo'),
      tr(
        'Funkce „Vyfotit stroj“ při výběru cviku odešle fotku a seznam názvů '
            'cviků z katalogu stejnou cestou do Cloudflare Workers AI. Fotka se '
            'neukládá ani neloguje. AI jen navrhne až tři cviky z katalogu, '
            'vybíráš ty; může se splést.',
        'The "Photograph machine" option when picking an exercise sends a '
            'photo and the list of catalog exercise names the same way to '
            'Cloudflare Workers AI. The photo is neither stored nor logged. AI '
            'only suggests up to three catalog exercises; you choose the '
            'exercise and it can be wrong.',
      ),
    ),
    (
      tr('AI: trenér', 'AI: coach'),
      tr(
        'Chat s trenérem odešle tvoji otázku, posledních až 12 zpráv chatu '
            'a krátký souhrn tréninků (program, poslední tréninky a série, '
            'rekordy, regeneraci, odpovědi z dotazníku plánu a u dospělých '
            'i tělesnou váhu) stejnou cestou do Cloudflare Workers AI. Jméno, '
            'poznámky ani celá historie se neposílají a nic z toho se na '
            'serveru neukládá. Chat (posledních 30 zpráv) zůstává v zařízení '
            'a je v záloze. Trenér je AI: může se splést a nenahrazuje lékaře '
            'ani trenéra naživo. Pod 18 let nedává rady k hubnutí ani '
            'doplňkům stravy.',
        'Coach chat sends your question, up to the last 12 chat messages, '
            'and a short workout summary (program, recent workouts and sets, '
            'records, recovery, plan quiz answers, and body weight for adults) '
            'the same way to Cloudflare Workers AI. Your name, notes and full '
            'history are not sent, and none of it is stored on the server. The '
            'chat (last 30 messages) stays on your device and is included in '
            'backups. The coach is AI: it can be wrong and does not replace a '
            'doctor or a live trainer. Under 18, it gives no weight-loss or '
            'supplement advice.',
      ),
    ),
    (
      tr('Figurky a technika cviků', 'Exercise figures and technique'),
      tr(
        'Figurky cviků kreslí aplikace sama, nic se kvůli nim nestahuje. '
            'Popisy techniky a častých chyb jsou naše vlastní a nenahrazují '
            'vedení trenéra.',
        'The app draws the exercise figures itself; nothing is downloaded '
            'for them. Technique and common-mistake descriptions are our own '
            'and do not replace a trainer’s guidance.',
      ),
    ),
    (
      tr('Záloha a smazání', 'Backup and deletion'),
      tr(
        'Protože data nejsou nikde jinde, ulož si zálohu do souboru '
            '(Nastavení, řádek Uložit zálohu). Smazáním dat prohlížeče, odinstalací '
            'nebo vyčištěním úložiště data zmizí. Všechno v zařízení smažeš '
            'v Nastavení, řádek Smazat všechna data.',
        'Because your data is nowhere else, save a backup to a file '
            '(Settings, "Save a backup"). Clearing browser data, uninstalling '
            'or wiping storage removes it. You can delete everything on the '
            'device in Settings, "Delete all data".',
      ),
    ),
    (
      tr('Zodpovědnost', 'Liability'),
      tr(
        'Aplikace se poskytuje tak, jak je, bez záruky. Za zranění, ztrátu dat '
            'ani jiné škody při používání autor neručí, v rozsahu, který '
            'dovoluje zákon.',
        'The app is provided as is, without warranty. To the extent the '
            'law allows, the author is not liable for injury, data loss or '
            'other damage from using it.',
      ),
    ),
    (
      tr('Změny a kontakt', 'Changes and contact'),
      tr(
        'Podmínky se mohou změnit; o podstatné změně se dozvíš v aplikaci. '
            'Dotazy a zpětnou vazbu pošli v Nastavení, řádek Napsat zpětnou vazbu.',
        'These terms may change; you will be told about significant changes '
            'in the app. Send questions and feedback in Settings, "Send feedback".',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LargeTitlePage(
      title: tr('Podmínky a soukromí', 'Terms and privacy'),
      padding: const EdgeInsets.fromLTRB(
        Space.page + Space.xs,
        Space.s,
        Space.page,
        Space.xxxl,
      ),
      children: [
        for (final (title, body) in sections()) ...[
          const SizedBox(height: Space.m),
          Text(title, style: text.titleMedium),
          const SizedBox(height: Space.xs),
          Text(body),
        ],
      ],
    );
  }
}

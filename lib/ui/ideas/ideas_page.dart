import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/tokens.dart';

/// Nápad do budoucna: nadpis a jedna věta.
typedef Idea = (String title, String detail);

/// Nápady, co by se dalo přidat, po skupinách. Nic z toho není slib;
/// stejný seznam je v `docs/napady/README.md`.
const ideaGroups = <(String, IconData, List<Idea>)>[
  (
    'Trénink',
    Icons.fitness_center_rounded,
    [
      ('Supersety a drop sety', 'Spojit dva cviky nebo série bez pauzy.'),
      ('Návody k cvikům', 'Krátký popis techniky a nejčastější chyby.'),
      ('Cviky na čas', 'Plank, kardio nebo strečink zapsat v minutách.'),
      ('Přesun cviku tažením', 'Pořadí cviků změnit prstem.'),
      ('Kalkulačka 1RM', 'Odhad maxima na jedno opakování z libovolné série.'),
    ],
  ),
  (
    'Pokrok',
    Icons.insights_rounded,
    [
      (
        'Shrnutí roku',
        'Tréninky, tuny, rekordy a nejlepší měsíc na jedné kartě.',
      ),
      ('Mapa těla', 'Postava, na které svítí unavené a odpočaté partie.'),
      ('Trend tělesné váhy', 'Vyhlazená křivka místo skákajících bodů.'),
      ('Porovnání dvou tréninků', 'Vybrat libovolné dva a vidět rozdíl.'),
    ],
  ),
  (
    'Motivace',
    Icons.local_fire_department_rounded,
    [
      ('Týdenní výzvy', 'Malý cíl navíc, třeba o jednu sérii víc na nohy.'),
      ('Sdílení odznaků', 'Poslat odemčený odznak jako obrázek.'),
      ('Plán na příští týden', 'Návrh tréninků podle toho, co chybělo.'),
    ],
  ),
  (
    'Strava',
    Icons.restaurant_rounded,
    [
      ('Nový vzhled Stravy', 'Stejně čistý jako Cvičení.'),
      ('Oblíbená jídla', 'Zapsat běžnou snídani jedním klepnutím.'),
    ],
  ),
  (
    'Telefon a zařízení',
    Icons.devices_rounded,
    [
      (
        'Widget na plochu',
        'Týdenní cíl a další trénink bez otevření aplikace.',
      ),
      ('Hodinky', 'Potvrzení série a pauza na zápěstí.'),
      ('Záloha do cloudu', 'Data v bezpečí i při ztrátě telefonu.'),
    ],
  ),
  (
    'S ostatními',
    Icons.groups_rounded,
    [
      (
        'Přátelé a jejich tréninky',
        'Potřebuje server, moderaci a ochranu mladších uživatelů.',
      ),
      ('Silové úrovně', 'Srovnání síly s ostatními podle váhy a pohlaví.'),
    ],
  ),
];

/// Nápady a plány: jednoduchý seznam bez hlasování a sítě.
class IdeasPage extends StatelessWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LargeTitlePage(
      title: 'Nápady',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
          child: Text(
            'Co by se do aplikace dalo přidat. Nic z toho zatím není slib. '
            'Chybí ti něco? Napiš v Nastavení, řádek Napsat zpětnou vazbu.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: p.secondaryLabel),
          ),
        ),
        for (final (name, _, ideas) in ideaGroups)
          GroupedSection(
            header: name,
            children: [
              for (final (title, detail) in ideas)
                GroupedRow(title: title, subtitle: detail, chevron: false),
            ],
          ),
      ],
    );
  }
}

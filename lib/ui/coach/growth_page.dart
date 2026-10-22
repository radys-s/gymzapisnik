import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../../coach/tips.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Rady pro maximální růst svalů a týdenní počet těžkých sérií na partii.
class GrowthPage extends StatelessWidget {
  final AppState state;
  final DateTime Function() now;
  const GrowthPage(this.state, {super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final sets = weeklyHardSets(
      state.workouts,
      now(),
      (id) => state.exercise(id).muscle,
    );
    final adult = state.profile.adult;
    return LargeTitlePage(
      title: 'Růst svalů',
      children: [
        Text(
          'Co podle výzkumů nejvíc pomáhá, aby svaly rostly. Obecné rady, '
          'ne lékařské doporučení; při bolesti nebo zranění se poraď s odborníkem.',
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
        const SectionHeader('Tvůj týden'),
        Panel(
          child: Column(
            children: [
              for (final f in dayFocuses)
                _VolumeRow(name: f.name, sets: sets[f.id] ?? 0),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 6, Space.l, 0),
          child: Text(
            'Potvrzené pracovní série za posledních 7 dní. Cíl pro růst je '
            'zhruba $weeklySetsMin–$weeklySetsMax sérií na partii týdně. '
            'Každá série se počítá jedné partii; vlastní cviky na paže se '
            'nepočítají.',
            style: text.bodySmall,
          ),
        ),
        const SectionHeader('Základy'),
        for (final r in _principles(adult)) _Principle(r),
      ],
    );
  }

  static List<_Rule> _principles(bool adult) => [
    const _Rule(
      Icons.stacked_bar_chart_rounded,
      Color(0xFF5E5CE6),
      'Objem: 10–20 sérií týdně',
      'Na každou partii 10–20 těžkých sérií za týden. Začni u spodní '
          'hranice a přidávej, jen když stíháš regenerovat.',
    ),
    const _Rule(
      Icons.local_fire_department_rounded,
      Color(0xFFFF6A1A),
      'Blízko selhání',
      'Pracovní série končí 0–3 opakování před selháním. U izolovaných '
          'cviků klidně až do selhání, u dřepu a mrtvého tahu s rezervou.',
    ),
    const _Rule(
      Icons.repeat_rounded,
      Color(0xFF14A9D0),
      'Opakování 6–30',
      'Svaly rostou v širokém rozsahu. Prakticky: 5–10 u těžkých '
          'vícekloubových cviků, 10–20 u izolací.',
    ),
    const _Rule(
      Icons.calendar_month_rounded,
      Color(0xFF34C759),
      'Každá partie 2× týdně',
      'Rozdělit stejný objem do dvou tréninků funguje lépe než jeden '
          'dlouhý trénink týdně.',
    ),
    const _Rule(
      Icons.trending_up_rounded,
      Color(0xFFFF9F0A),
      'Postupné přetížení',
      'Nejdřív přidej opakování, pak váhu. Aplikace to hlídá: když dáš '
          'horní hranici ve všech sériích, navrhne vyšší váhu.',
    ),
    const _Rule(
      Icons.call_split_rounded,
      Color(0xFFAF52DE),
      'Všechny hlavy svalu',
      'Kombinuj vícekloubové a izolované cviky. Dlouhá hlava tricepsu '
          'potřebuje cvik nad hlavou, boční delt upažování. V tréninku najdeš '
          'u cviku tlačítko Vyměnit nabídne alternativy podle hlavy svalu.',
    ),
    const _Rule(
      Icons.open_in_full_rounded,
      Color(0xFF0B7A70),
      'Plný rozsah a kontrola',
      'Celý rozsah pohybu, hlavně v protažení svalu. Váhu spouštěj pod '
          'kontrolou zhruba 2–3 sekundy.',
    ),
    const _Rule(
      Icons.timer_outlined,
      Color(0xFF8E8E93),
      'Pauzy',
      'Mezi těžkými sériemi 2–3 minuty, u izolací 1–2 minuty. Krátké '
          'pauzy ubírají opakování v dalších sériích.',
    ),
    _Rule(
      Icons.restaurant_rounded,
      const Color(0xFFFF375F),
      'Jídlo a bílkoviny',
      adult
          ? 'Bílkoviny zhruba 1,6–2,2 g na kilo tělesné váhy denně, '
                'rozdělené do 3–5 jídel. Mírný přebytek energie nabírání '
                'urychlí; velký přidá hlavně tuk.'
          : 'Jez pravidelně a dost, ať máš energii na trénink i růst. '
                'Bílkoviny ber z běžného jídla (maso, vejce, mléčné výrobky, '
                'luštěniny). Nedrž diety a nehubni bez lékaře.',
    ),
    const _Rule(
      Icons.bedtime_rounded,
      Color(0xFF5856D6),
      'Spánek 7–9 hodin',
      'Sval roste při odpočinku. Málo spánku zhoršuje výkon i regeneraci.',
    ),
    const _Rule(
      Icons.battery_charging_full_rounded,
      Color(0xFF30B0C7),
      'Lehčí týden',
      'Když se výkon několik týdnů nehýbe nebo jsi pořád unavený, dej si '
          'týden s polovičním objemem a pak pokračuj.',
    ),
    const _Rule(
      Icons.hourglass_bottom_rounded,
      Color(0xFF636366),
      'Trpělivost',
      'První rok jde růst nejrychleji, pak zpomalí. Rozhoduje, kolik '
          'týdnů za sebou odcvičíš, ne jeden perfektní trénink.',
    ),
  ];
}

class _Rule {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Rule(this.icon, this.color, this.title, this.body);
}

class _Principle extends StatelessWidget {
  final _Rule rule;
  const _Principle(this.rule);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(rule.icon, color: rule.color, size: 34),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.title, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    rule.body,
                    style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final String name;
  final int sets;
  const _VolumeRow({required this.name, required this.sets});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (label, color) = sets == 0
        ? ('nic', p.tertiaryLabel)
        : sets < weeklySetsMin
        ? ('málo', p.secondaryLabel)
        : sets <= weeklySetsMax
        ? ('v cíli', p.positive)
        : ('hodně', p.negative);
    return Semantics(
      container: true,
      label: '$name: $sets sérií, $label',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: text.bodyLarge)),
                  Text(
                    '$sets · $label',
                    style: text.bodyMedium?.copyWith(color: color),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (sets / weeklySetsMax).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: p.fill,
                  color: sets >= weeklySetsMin ? p.positive : p.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

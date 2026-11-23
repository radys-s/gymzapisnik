import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../../coach/tips.dart';
import '../../core/i18n.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../widgets/labels.dart';

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
      title: tr('Růst svalů', 'Muscle growth'),
      children: [
        Text(
          tr(
            'Co podle výzkumů nejvíc pomáhá, aby svaly rostly. Obecné rady, '
                'ne lékařské doporučení; při bolesti nebo zranění se poraď s odborníkem.',
            'What research says helps muscles grow. General advice, not '
                'medical guidance; see a professional if you feel pain or get injured.',
          ),
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
        SectionHeader(tr('Tvůj týden', 'Your week')),
        Panel(
          child: Column(
            children: [
              for (final f in dayFocuses)
                _VolumeRow(name: muscleLabel(f.name), sets: sets[f.id] ?? 0),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 6, Space.l, 0),
          child: Text(
            tr(
              'Potvrzené pracovní série za posledních 7 dní. Cíl pro růst je '
                  'zhruba $weeklySetsMin–$weeklySetsMax sérií na partii týdně. '
                  'Každá série se počítá jedné partii; vlastní cviky na paže se '
                  'nepočítají.',
              'Logged working sets in the last 7 days. Growth target is about '
                  '$weeklySetsMin–$weeklySetsMax sets per muscle group per week. '
                  'Each set counts for one group; custom arm exercises are excluded.',
            ),
            style: text.bodySmall,
          ),
        ),
        SectionHeader(tr('Základy', 'The basics')),
        for (final r in _principles(adult)) _Principle(r),
      ],
    );
  }

  static List<_Rule> _principles(bool adult) => [
    _Rule(
      Icons.stacked_bar_chart_rounded,
      tr('Objem: 10–20 sérií týdně', 'Volume: 10–20 sets a week'),
      tr(
        'Na každou partii 10–20 těžkých sérií za týden. Začni u spodní '
            'hranice a přidávej, jen když stíháš regenerovat.',
        '10–20 hard sets per muscle group each week. Start at the low end '
            'and add more only if you recover well.',
      ),
    ),
    _Rule(
      Icons.local_fire_department_rounded,
      tr('Blízko selhání', 'Close to failure'),
      tr(
        'Pracovní série končí 0–3 opakování před selháním. U izolovaných '
            'cviků klidně až do selhání, u dřepu a mrtvého tahu s rezervou.',
        'Working sets end 0–3 reps short of failure. Go to failure on '
            'isolation work, but leave gas in the tank on squats and deadlifts.',
      ),
    ),
    _Rule(
      Icons.repeat_rounded,
      tr('Opakování 6–30', 'Reps: 6–30'),
      tr(
        'Svaly rostou v širokém rozsahu. Prakticky: 5–10 u těžkých '
            'vícekloubových cviků, 10–20 u izolací.',
        'Muscles grow across a wide rep range. In practice: 5–10 on heavy '
            'compounds, 10–20 on isolation work.',
      ),
    ),
    _Rule(
      Icons.calendar_month_rounded,
      tr('Každá partie 2× týdně', 'Train each group twice a week'),
      tr(
        'Rozdělit stejný objem do dvou tréninků funguje lépe než jeden '
            'dlouhý trénink týdně.',
        'Splitting the same volume across two sessions beats one long '
            'weekly workout.',
      ),
    ),
    _Rule(
      Icons.trending_up_rounded,
      tr('Postupné přetížení', 'Progressive overload'),
      tr(
        'Nejdřív přidej opakování, pak váhu. Aplikace to hlídá: když dáš '
            'horní hranici ve všech sériích, navrhne vyšší váhu.',
        'Add reps first, then weight. The app tracks it: when you hit the '
            'top of the rep range in every set, it suggests heavier weight.',
      ),
    ),
    _Rule(
      Icons.call_split_rounded,
      tr('Všechny hlavy svalu', 'Hit every muscle head'),
      tr(
        'Kombinuj vícekloubové a izolované cviky. Dlouhá hlava tricepsu '
            'potřebuje cvik nad hlavou, boční delt upažování. V tréninku najdeš '
            'u cviku tlačítko Vyměnit nabídne alternativy podle hlavy svalu.',
        'Mix compounds and isolation work. The long triceps head needs '
            'overhead work, the side delt needs lateral raises. In a workout, '
            'the Swap button offers alternatives by muscle head.',
      ),
    ),
    _Rule(
      Icons.open_in_full_rounded,
      tr('Plný rozsah a kontrola', 'Full range and control'),
      tr(
        'Celý rozsah pohybu, hlavně v protažení svalu. Váhu spouštěj pod '
            'kontrolou zhruba 2–3 sekundy.',
        'Use the full range of motion, especially the stretch. Lower the '
            'weight under control for about 2–3 seconds.',
      ),
    ),
    _Rule(
      Icons.timer_outlined,
      tr('Pauzy', 'Rest'),
      tr(
        'Mezi těžkými sériemi 2–3 minuty, u izolací 1–2 minuty. Krátké '
            'pauzy ubírají opakování v dalších sériích.',
        'Rest 2–3 minutes on heavy sets, 1–2 on isolation work. Short rests '
            'cost you reps on later sets.',
      ),
    ),
    _Rule(
      Icons.restaurant_rounded,
      tr('Jídlo a bílkoviny', 'Food and protein'),
      adult
          ? tr(
              'Bílkoviny zhruba 1,6–2,2 g na kilo tělesné váhy denně, '
                  'rozdělené do 3–5 jídel. Mírný přebytek energie nabírání '
                  'urychlí; velký přidá hlavně tuk.',
              'About 1.6–2.2 g of protein per kilo of body weight daily, '
                  'spread over 3–5 meals. A small calorie surplus helps you gain '
                  'muscle; a large one mostly adds fat.',
            )
          : tr(
              'Jez pravidelně a dost, ať máš energii na trénink i růst. '
                  'Bílkoviny ber z běžného jídla (maso, vejce, mléčné výrobky, '
                  'luštěniny). Nedrž diety a nehubni bez lékaře.',
              'Eat regularly and enough to fuel training and growth. Get '
                  'protein from normal food (meat, eggs, dairy, legumes). Do not '
                  'diet or cut without a doctor.',
            ),
    ),
    _Rule(
      Icons.bedtime_rounded,
      tr('Spánek 7–9 hodin', 'Sleep 7–9 hours'),
      tr(
        'Sval roste při odpočinku. Málo spánku zhoršuje výkon i regeneraci.',
        'Muscle grows while you rest. Too little sleep hurts performance '
            'and recovery.',
      ),
    ),
    _Rule(
      Icons.battery_charging_full_rounded,
      tr('Lehčí týden', 'Deload week'),
      tr(
        'Když se výkon několik týdnů nehýbe nebo jsi pořád unavený, dej si '
            'týden s polovičním objemem a pak pokračuj.',
        'If performance stalls for weeks or you feel constantly tired, '
            'take a week at half volume and then build back up.',
      ),
    ),
    _Rule(
      Icons.hourglass_bottom_rounded,
      tr('Trpělivost', 'Patience'),
      tr(
        'První rok jde růst nejrychleji, pak zpomalí. Rozhoduje, kolik '
            'týdnů za sebou odcvičíš, ne jeden perfektní trénink.',
        'Growth is fastest in your first year, then slows. What matters is '
            'how many weeks in a row you train, not one perfect workout.',
      ),
    ),
  ];
}

class _Rule {
  final IconData icon;
  final String title;
  final String body;
  const _Rule(this.icon, this.title, this.body);
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
            IconTile(rule.icon, color: p.secondaryLabel, size: 34),
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
        ? (tr('nic', 'none'), p.tertiaryLabel)
        : sets < weeklySetsMin
        ? (tr('málo', 'low'), p.secondaryLabel)
        : sets <= weeklySetsMax
        ? (tr('v cíli', 'on target'), p.positive)
        : (tr('hodně', 'high'), p.negative);
    return Semantics(
      container: true,
      label: tr('$name: $sets sérií, $label', '$name: $sets sets, $label'),
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

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Vydání, ke kterému patří novinky níže. Při nových novinkách zvyš,
/// ať se okno ukáže jednou každému, kdo je ještě neviděl.
const whatsNewRelease = '1.8';

/// Novinky aktuálního vydání: ikona, nadpis, jedna věta.
List<(IconData, String, String)> whatsNewItems() => [
  (
    Icons.check_circle_outline_rounded,
    tr('Potvrzení přímo v úpravě série', 'Confirm sets while editing'),
    tr(
      'Po změně váhy nebo opakování stačí „Potvrdit sérii“, fajfku v řádku '
          'už hledat nemusíš.',
      'After changing weight or reps, just tap "Confirm set" — no need to '
          'hunt for the checkmark.',
    ),
  ),
  (
    Icons.edit_note_rounded,
    tr('Chybějící číslo doplníš hned', 'Fill in missing numbers right away'),
    tr(
      'Fajfka u prázdné série otevře úpravu s kurzorem tam, kde číslo chybí.',
      'The checkmark on an empty set opens editing with the cursor where '
          'the number is missing.',
    ),
  ),
  (
    Icons.edit_outlined,
    tr('Oprava hned po tréninku', 'Fix workouts right after training'),
    tr(
      'Tužka v souhrnu otevře úpravu tréninku, bez cesty přes historii.',
      'The pencil in the summary opens workout editing without going '
          'through history.',
    ),
  ),
  (
    Icons.timer_outlined,
    tr('Tlačítka pauzy se už nezmenšují', 'Rest buttons keep their size'),
    tr(
      '−15, +15 a Přeskočit mají plnou velikost i na menším telefonu.',
      '−15, +15 and Skip stay full size even on smaller phones.',
    ),
  ),
  (
    Icons.history_rounded,
    tr('Historie jedním klepnutím', 'History in one tap'),
    tr(
      'V Pokroku otevřeš historii i s hledáním ikonou nahoře vedle '
          'nastavení.',
      'In Progress, history and search are an icon away at the top next '
          'to settings.',
    ),
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
        for (final (icon, title, body) in whatsNewItems())
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
              tr('Co je nového', "What's new"),
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.l),
            const WhatsNewList(),
            const SizedBox(height: Space.xl),
            PrimaryButton(
              tr('Pokračovat', 'Continue'),
              onPressed: () => Navigator.pop(sheet),
            ),
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
  Widget build(BuildContext context) => LargeTitlePage(
    title: tr('Novinky', "What's new"),
    children: const [Panel(child: WhatsNewList())],
  );
}

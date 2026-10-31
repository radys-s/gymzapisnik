import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Výběr barvy motivu: vzorek přechodu, název, popis a fajfka.
class AccentPicker extends StatelessWidget {
  final Accent selected;
  final ValueChanged<Accent> onChanged;
  const AccentPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final brightness = Theme.of(context).brightness;
    return GroupedSection(
      header: 'Barva',
      dividerIndent: 72,
      children: [
        for (final a in Accent.values)
          Semantics(
            selected: a == selected,
            inMutuallyExclusiveGroup: true,
            child: GroupedRow(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: a.gradient(brightness),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: a.label,
              subtitle: a.description,
              chevron: false,
              trailing: a == selected
                  ? Icon(Icons.check_rounded, color: p.accent)
                  : const SizedBox(width: 24),
              onTap: () => onChanged(a),
            ),
          ),
      ],
    );
  }
}

/// Výběr vzhledu: Automaticky / Aurora / Studio s malým náhledem.
class LookPicker extends StatelessWidget {
  final Look selected;
  final ValueChanged<Look> onChanged;
  const LookPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GroupedSection(
      header: 'Vzhled',
      dividerIndent: 72,
      children: [
        for (final l in Look.values)
          Semantics(
            selected: l == selected,
            inMutuallyExclusiveGroup: true,
            child: GroupedRow(
              leading: _LookSwatch(l, p.preset),
              title: l.label,
              subtitle: l.description,
              chevron: false,
              trailing: l == selected
                  ? Icon(Icons.check_rounded, color: p.accent)
                  : const SizedBox(width: 24),
              onTap: () => onChanged(l),
            ),
          ),
      ],
    );
  }
}

/// Miniatura vzhledu: Aurora = světlá s barevnou kartou,
/// Studio = tmavá se září, Automaticky = půl na půl.
class _LookSwatch extends StatelessWidget {
  final Look look;
  final Accent accent;
  const _LookSwatch(this.look, this.accent);

  @override
  Widget build(BuildContext context) {
    Widget aurora() => Container(
      color: const Color(0xFFF4F4F7),
      padding: const EdgeInsets.all(6),
      alignment: Alignment.topLeft,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(colors: accent.gradient(Brightness.light)),
        ),
      ),
    );
    Widget studio() {
      final g = accent.gradient(Brightness.dark);
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E10),
          gradient: RadialGradient(
            center: const Alignment(-1, -1),
            radius: 1.3,
            colors: [deepTone(g.last), const Color(0xFF0E0E10)],
          ),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(7),
        child: Container(
          height: 7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    // Závod: tmavá tabule s červeným pruhem a světlem startu.
    Widget pitwall() => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF15151E),
        border: Border(left: BorderSide(color: AppPalette.raceRed, width: 4)),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.fromLTRB(4, 7, 7, 7),
      child: Container(height: 7, color: AppPalette.raceRed),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox.square(
        dimension: 40,
        child: switch (look) {
          Look.pitwall => pitwall(),
          Look.aurora => aurora(),
          Look.studio => studio(),
          Look.auto => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: aurora()),
              Expanded(child: studio()),
            ],
          ),
        },
      ),
    );
  }
}

/// Uloží barvu; chybu ukáže, místo aby tiše zmizela.
Future<void> saveAccent(BuildContext context, AppState state, Accent a) async {
  try {
    await state.setPreferences(accent: a.name);
  } catch (e) {
    if (context.mounted) showToast(context, 'Barvu se nepodařilo uložit: $e');
  }
}

/// Uloží vzhled; chybu ukáže.
Future<void> saveLook(BuildContext context, AppState state, Look l) async {
  try {
    await state.setPreferences(look: l.name);
  } catch (e) {
    if (context.mounted) showToast(context, 'Vzhled se nepodařilo uložit: $e');
  }
}

/// Vzhled a barva: výběr i náhled pohromadě (úvod i Nastavení).
class AppearanceOptions extends StatelessWidget {
  final AppState state;
  const AppearanceOptions(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Náhled nahoře: hned vidět, co volba udělá.
        const AccentPreview(),
        const SizedBox(height: Space.xxl),
        LookPicker(
          selected: Look.parse(state.profile.look),
          onChanged: (l) => saveLook(context, state, l),
        ),
        // Závod má pevnou závodní červenou, barva motivu by nic nezměnila.
        if (Look.parse(state.profile.look) != Look.pitwall)
          AccentPicker(
            selected: Accent.parse(state.profile.accent),
            onChanged: (a) => saveAccent(context, state, a),
          ),
      ],
    ),
  );
}

/// Změna vzhledu a barvy z Nastavení.
class AppearancePage extends StatelessWidget {
  final AppState state;
  const AppearancePage(this.state, {super.key});

  @override
  Widget build(BuildContext context) =>
      LargeTitlePage(title: 'Vzhled', children: [AppearanceOptions(state)]);
}

/// Ukázka hlavní karty, tlačítka a kruhu postupu ve zvoleném vzhledu.
/// Jen obrázek: nic se nedá stisknout a čtečka ho přeskočí.
class AccentPreview extends StatelessWidget {
  const AccentPreview({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: HeroCard(
        vivid: true,
        child: Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('DNES PODLE PROGRAMU', style: text.labelSmall),
                const SizedBox(height: 2),
                Text('Push', style: text.headlineSmall),
                const SizedBox(height: Space.l),
                Row(
                  children: [
                    const ProgressRing(
                      value: 2 / 3,
                      size: 52,
                      stroke: 6,
                      child: Text('2/3'),
                    ),
                    const SizedBox(width: Space.l),
                    Expanded(
                      child: PrimaryButton('Začít trénink', onPressed: () {}),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

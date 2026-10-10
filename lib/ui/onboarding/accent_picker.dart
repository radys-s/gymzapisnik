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

/// Uloží barvu; chybu ukáže, místo aby tiše zmizela.
Future<void> saveAccent(BuildContext context, AppState state, Accent a) async {
  try {
    await state.setPreferences(accent: a.name);
  } catch (e) {
    if (context.mounted) showToast(context, 'Barvu se nepodařilo uložit: $e');
  }
}

/// Změna barvy z Nastavení.
class AccentPage extends StatelessWidget {
  final AppState state;
  const AccentPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => LargeTitlePage(
      title: 'Barva',
      children: [
        AccentPicker(
          selected: Accent.parse(state.profile.accent),
          onChanged: (a) => saveAccent(context, state, a),
        ),
        const AccentPreview(),
      ],
    ),
  );
}

/// Ukázka, jak barva vypadá na hlavním tlačítku a kruhu postupu.
/// Jen obrázek: nic se nedá stisknout a čtečka ho přeskočí.
class AccentPreview extends StatelessWidget {
  const AccentPreview({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: HeroCard(
        child: Row(
          children: [
            const ProgressRing(value: 2 / 3, size: 64, child: Text('2/3')),
            const SizedBox(width: Space.l),
            Expanded(child: PrimaryButton('Začít trénink', onPressed: () {})),
          ],
        ),
      ),
    ),
  );
}

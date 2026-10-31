import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../settings/legal_page.dart';

enum AgeChoice { adult, minor }

/// Souhlas s podmínkami a potvrzení věku (poslední krok prvního spuštění).
class ConsentPage extends StatefulWidget {
  final AppState state;

  /// Co uložit těsně před souhlasem (např. že uvítání proběhlo).
  /// Při prvním spuštění uzavře souhlas i uvítání (verze novinek).
  final String? welcomeVersion;
  const ConsentPage(this.state, {super.key, this.welcomeVersion});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool termsAccepted = false;
  AgeChoice? age;
  bool guardianConsent = false;
  bool saving = false;

  bool get canContinue =>
      termsAccepted &&
      (age == AgeChoice.adult || (age == AgeChoice.minor && guardianConsent));

  Future<void> _continue() async {
    setState(() => saving = true);
    try {
      await widget.state.acceptConsent(
        adult: age == AgeChoice.adult,
        guardianConsent: guardianConsent,
        welcomeVersion: widget.welcomeVersion,
        aiNotice: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      showToast(context, 'Uložení se nezdařilo: $error');
    }
  }

  void _openTerms() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LegalPage()),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.xxxl,
            Space.page,
            Space.xxl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    container: true,
                    header: true,
                    child: Text('Než začneš', style: text.headlineLarge),
                  ),
                  const SizedBox(height: Space.m),
                  Text(
                    'Gym zápisník slouží k zápisu tréninků a jídla a ke '
                    'sledování pokroku. Není to lékařská ani výživová rada. '
                    'Při bolesti nebo zdravotních potížích přestaň cvičit '
                    'a poraď se s lékařem.',
                    style: text.bodyLarge?.copyWith(color: p.secondaryLabel),
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    'Otázky trenérovi a fotky jdou do Cloudflare Workers AI '
                    'bez jména a poznámek. AI se může splést.',
                    style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _openTerms,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, minTap),
                      ),
                      child: const Text('Přečíst podmínky a soukromí'),
                    ),
                  ),
                  const SizedBox(height: Space.m),
                ],
              ),
            ),
            GroupedSection(
              children: [
                CheckboxListTile(
                  value: termsAccepted,
                  onChanged: (v) => setState(() => termsAccepted = v == true),
                  title: const Text('Souhlasím s podmínkami používání'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            RadioGroup<AgeChoice>(
              groupValue: age,
              onChanged: (v) => setState(() {
                age = v;
                if (v != AgeChoice.minor) guardianConsent = false;
              }),
              child: GroupedSection(
                header: 'Kolik ti je let?',
                footer: age == AgeChoice.minor
                    ? 'Mladším 18 let aplikace nenabízí cíle hubnutí '
                          'ani omezování jídla.'
                    : null,
                children: [
                  const RadioListTile(
                    value: AgeChoice.adult,
                    title: Text('Je mi 18 let nebo víc'),
                  ),
                  const RadioListTile(
                    value: AgeChoice.minor,
                    title: Text('Je mi méně než 18 let'),
                  ),
                  if (age == AgeChoice.minor)
                    CheckboxListTile(
                      value: guardianConsent,
                      onChanged: (v) =>
                          setState(() => guardianConsent = v == true),
                      title: const Text(
                        'Mám souhlas rodiče nebo zákonného zástupce',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                ],
              ),
            ),
            PrimaryButton(
              'Pokračovat',
              busy: saving,
              onPressed: canContinue ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}

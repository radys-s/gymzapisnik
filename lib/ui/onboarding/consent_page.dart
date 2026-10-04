import 'package:flutter/material.dart';

import '../../state/app_state.dart';

enum AgeChoice { adult, minor }

/// První spuštění: souhlas s podmínkami a potvrzení věku.
class ConsentPage extends StatefulWidget {
  final AppState state;
  const ConsentPage(this.state, {super.key});

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
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Uložení se nezdařilo: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Text('Než začneš', style: text.headlineMedium),
            const SizedBox(height: 16),
            const Text(
              'Aplikace slouží k zápisu tréninků a sledování pokroku. '
              'Není to lékařská ani výživová rada. Při bolesti nebo zdravotních '
              'potížích přestaň cvičit a poraď se s lékařem.\n\n'
              'Data se ukládají jen v tomto zařízení, dokud si nezapneš '
              'synchronizaci.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: termsAccepted,
              onChanged: (v) => setState(() => termsAccepted = v == true),
              title: const Text('Souhlasím s podmínkami používání'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            Text('Kolik ti je let?', style: text.titleMedium),
            RadioGroup<AgeChoice>(
              groupValue: age,
              onChanged: (v) => setState(() {
                age = v;
                if (v != AgeChoice.minor) guardianConsent = false;
              }),
              child: const Column(
                children: [
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: AgeChoice.adult,
                    title: Text('Je mi 18 let nebo víc'),
                  ),
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: AgeChoice.minor,
                    title: Text('Je mi méně než 18 let'),
                  ),
                ],
              ),
            ),
            if (age == AgeChoice.minor)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: guardianConsent,
                onChanged: (v) => setState(() => guardianConsent = v == true),
                title: const Text('Mám souhlas rodiče nebo zákonného zástupce'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canContinue && !saving ? _continue : null,
              child: Text(saving ? 'Ukládám…' : 'Pokračovat'),
            ),
          ],
        ),
      ),
    );
  }
}

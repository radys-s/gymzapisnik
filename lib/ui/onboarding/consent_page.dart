import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../settings/legal_page.dart';
import 'question.dart';

enum AgeChoice { adult, minor }

/// Souhlas s podmínkami a potvrzení věku. V úvodu je hned za uvítáním,
/// takže se na věk ptá aplikace jen jednou a dřív než na cokoli jiného.
class ConsentPage extends StatefulWidget {
  final AppState state;

  /// Krok úvodu, kterým se po souhlasu pokračuje. Bez něj souhlas
  /// rovnou pustí do aplikace (nové podmínky u stávajícího uživatele).
  final int? resumeAt;

  /// Zavolá se po uložení souhlasu.
  final VoidCallback? onAccepted;
  final VoidCallback? onBack;

  const ConsentPage(
    this.state, {
    super.key,
    this.resumeAt,
    this.onAccepted,
    this.onBack,
  });

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
        onboardingStep: widget.resumeAt,
        aiNotice: true,
      );
      if (!mounted) return;
      setState(() => saving = false);
      widget.onAccepted?.call();
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

  void _setAge(AgeChoice v) => setState(() {
    age = v;
    if (v != AgeChoice.minor) guardianConsent = false;
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final minor = age == AgeChoice.minor;
    return QuestionScaffold(
      tone: Tone.progress,
      title: 'Než začneš',
      action: 'Pokračovat',
      busy: saving,
      onBack: widget.onBack,
      onNext: canContinue ? _continue : null,
      child: StaggerColumn(
        children: [
          Text(
            'Gym zápisník slouží k zápisu tréninků a jídla a ke '
            'sledování pokroku. Není to lékařská ani výživová rada. '
            'Při bolesti nebo zdravotních potížích přestaň cvičit '
            'a poraď se s lékařem.',
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
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
          const SizedBox(height: Space.xs),
          ChoiceCard(
            icon: Icons.description_outlined,
            color: AppPalette.violet,
            label: 'Souhlasím s podmínkami používání',
            multi: true,
            selected: termsAccepted,
            onTap: () => setState(() => termsAccepted = !termsAccepted),
          ),
          const SizedBox(height: Space.xl),
          Text('Kolik ti je let?', style: text.titleMedium),
          const SizedBox(height: Space.s),
          ChoiceCard(
            icon: Icons.verified_user_outlined,
            color: AppPalette.cyan,
            label: 'Je mi 18 let nebo víc',
            selected: age == AgeChoice.adult,
            onTap: () => _setAge(AgeChoice.adult),
          ),
          const SizedBox(height: Space.s),
          ChoiceCard(
            icon: Icons.school_outlined,
            color: AppPalette.amber,
            label: 'Je mi méně než 18 let',
            hint: minor ? 'Bez cílů hubnutí a omezování jídla' : null,
            selected: minor,
            onTap: () => _setAge(AgeChoice.minor),
          ),
          if (minor) ...[
            const SizedBox(height: Space.s),
            ChoiceCard(
              icon: Icons.family_restroom_rounded,
              color: AppPalette.amber,
              label: 'Mám souhlas rodiče nebo zákonného zástupce',
              multi: true,
              selected: guardianConsent,
              onTap: () => setState(() => guardianConsent = !guardianConsent),
            ),
          ],
        ],
      ),
    );
  }
}

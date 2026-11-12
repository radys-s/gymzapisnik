/// Verze aplikace; musí odpovídat `version` v `pubspec.yaml` (hlídá test).
const appVersion = '1.0.0-beta.12+21';

/// Kam testeři píšou zpětnou vazbu. Doplní se buildem
/// (`--dart-define=FEEDBACK_EMAIL=…`), v repozitáři žádná adresa není.
const feedbackContact = String.fromEnvironment('FEEDBACK_EMAIL');

/// Veřejný kontakt projektu (např. pro User-Agent u Open Food Facts).
const projectUrl = 'https://github.com/radys-s/gymzapisnik';

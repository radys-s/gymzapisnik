/// Klíče v `Profile.extra`. Jediné místo, kde jsou napsané jako text:
/// překlep v názvu klíče by tiše ztratil nastavení, a hodnoty se ukládají
/// do zálohy, takže se názvy nesmí měnit.
abstract final class ProfileKey {
  // Úvod a souhlas
  static const welcomeSeen = 'welcomeSeen';
  static const seenVersion = 'seenVersion';
  static const onboardingStep = 'onboardingStep';
  static const aiNotice = 'aiNotice';

  // Plán a program
  static const plan = 'plan';
  static const planDraft = 'planDraft';
  static const split = 'split';
  static const programs = 'programs';
  static const weekGoal = 'weekGoal';
  static const trainingDays = 'trainingDays';
  static const weekFocus = 'weekFocus';

  // Trénink
  static const restSeconds = 'restSeconds';
  static const restByExercise = 'restByExercise';
  static const restAlerts = 'restAlerts';
  static const weightStep = 'weightStep';
  static const reminder = 'reminder';
  static const exerciseNotes = 'exerciseNotes';
  static const strengthStandard = 'strengthStandard';

  // Výživa a AI kouč
  static const proteinTarget = 'proteinTarget';
  static const kcalTarget = 'kcalTarget';
  static const favoriteFoods = 'favoriteFoods';
  static const pantry = 'pantry';
  static const pantryExcluded = 'pantryExcluded';
  static const pantryMinutes = 'pantryMinutes';
  static const mealIdeas = 'mealIdeas';
  static const coachChat = 'coachChat';

  // Aplikace
  static const tab = 'tab4';
  static const pro = 'pro';
  static const backupCount = 'backupCount';
  static const installId = 'installId';

  /// Starší verze ukládaly záložku jinak; čtou se jen kvůli převodu.
  static const legacyTab = 'tab';
  static const legacyLastTab = 'lastTab';

  /// Všechny klíče, které aplikace zapisuje nebo čte.
  static const all = {
    welcomeSeen,
    seenVersion,
    onboardingStep,
    aiNotice,
    plan,
    planDraft,
    split,
    programs,
    weekGoal,
    trainingDays,
    weekFocus,
    restSeconds,
    restByExercise,
    restAlerts,
    weightStep,
    reminder,
    exerciseNotes,
    strengthStandard,
    proteinTarget,
    kcalTarget,
    favoriteFoods,
    pantry,
    pantryExcluded,
    pantryMinutes,
    mealIdeas,
    coachChat,
    tab,
    pro,
    backupCount,
    installId,
    legacyTab,
    legacyLastTab,
  };
}

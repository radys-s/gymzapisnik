import 'plan_quiz.dart';

/// Doporučený denní cíl: bílkoviny vždy, energie jen pro dospělé.
typedef SuggestedTargets = ({double protein, double? kcal});

/// Bílkoviny v g na kg tělesné váhy podle cíle (rozmezí 1,6–2,0 g/kg,
/// které podporují studie u silového tréninku).
double proteinPerKg(PlanGoal goal) => switch (goal) {
  PlanGoal.muscle => 2.0,
  PlanGoal.strength => 1.8,
  PlanGoal.fitness => 1.6,
};

/// Cíl z tělesné váhy [kg] a cíle tréninku. Bílkoviny se zaokrouhlí na
/// 5 g; při hubnutí aspoň 2 g/kg, ať se drží svaly. Energie: se
/// zadaným pohlavím, výškou a věkem podle Mifflin-St Jeor krát
/// aktivita podle počtu tréninků, jinak hrubý odhad 33 kcal/kg. Pak
/// přebytek nebo deficit podle cíle váhy, na 50 kcal. Mladším 18 let
/// aplikace kalorický cíl nenabízí.
SuggestedTargets suggestTargets({
  required double kg,
  required PlanGoal goal,
  required bool adult,
  PlanAnswers? plan,
  DateTime? now,
}) {
  // Cíl hubnutí platí jen pro dospělé.
  final weightGoal = adult ? plan?.weightGoal : null;
  var perKg = proteinPerKg(goal);
  if (weightGoal == WeightGoal.lose && perKg < 2.0) perKg = 2.0;
  final protein = ((kg * perKg) / 5).round() * 5.0;
  final surplus =
      weightGoal?.kcal ??
      switch (goal) {
        PlanGoal.muscle => 250,
        PlanGoal.strength => 150,
        PlanGoal.fitness => 0,
      };
  final maintenance = _maintenance(kg, plan, now ?? DateTime.now());
  final kcal = ((maintenance + surplus) / 50).round() * 50.0;
  return (
    protein: protein.clamp(20, 400).toDouble(),
    kcal: adult ? kcal.clamp(1000, 6000).toDouble() : null,
  );
}

/// Udržovací příjem v kcal.
double _maintenance(double kg, PlanAnswers? plan, DateTime now) {
  final sex = plan?.sex;
  final cm = plan?.heightCm;
  final age = plan?.ageIn(now);
  if (plan == null || sex == null || cm == null || age == null) {
    return kg * 33;
  }
  final bmr = 10 * kg + 6.25 * cm - 5 * age + (sex == Sex.male ? 5 : -161);
  final activity = switch (plan.days) {
    <= 3 => 1.45,
    <= 5 => 1.6,
    _ => 1.7,
  };
  return bmr * activity;
}

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
/// 5 g. Energie je hrubý odhad udržovacího příjmu aktivního člověka
/// (33 kcal/kg) s mírným přebytkem pro nabírání, na 50 kcal. Mladším
/// 18 let aplikace kalorický cíl nenabízí.
SuggestedTargets suggestTargets({
  required double kg,
  required PlanGoal goal,
  required bool adult,
}) {
  final protein = ((kg * proteinPerKg(goal)) / 5).round() * 5.0;
  final surplus = switch (goal) {
    PlanGoal.muscle => 250,
    PlanGoal.strength => 150,
    PlanGoal.fitness => 0,
  };
  final kcal = ((kg * 33 + surplus) / 50).round() * 50.0;
  return (
    protein: protein.clamp(20, 400).toDouble(),
    kcal: adult ? kcal.clamp(1000, 6000).toDouble() : null,
  );
}

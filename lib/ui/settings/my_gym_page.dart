import 'package:flutter/material.dart';

import '../../ai/fridge_coach.dart' show AiError, AiOk;
import '../../ai/photo.dart';
import '../../coach/plan_quiz.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../onboarding/onboarding_page.dart' show placeIcon;
import '../onboarding/question.dart';
import '../widgets/ai_photo.dart';
import '../widgets/exercise_media.dart';

/// Vybavení, u kterého dává smysl se ptát, jestli ho posilovna má.
const _machineGear = {
  Equipment.machine,
  Equipment.cable,
  Equipment.smith,
  Equipment.plate,
};

/// Cviky na stroje, které v posilovně podle typu můžou být, po partiích.
Map<String, List<Exercise>> gymMachinesByMuscle(TrainingPlace place) {
  final out = <String, List<Exercise>>{};
  for (final e in builtInExercises) {
    if (!_machineGear.contains(e.equipment) || !place.allows(e.equipment)) {
      continue;
    }
    (out[e.muscle] ??= []).add(e);
  }
  return {
    for (final m in muscleGroups)
      m: ?out[m],
  };
}

/// Moje posilovna: typ posilovny a stroje, které tam jsou. Plán pak
/// navrhuje jen cviky, které jdou odcvičit.
class MyGymPage extends StatefulWidget {
  final AppState state;
  final PhotoPicker picker;
  const MyGymPage(this.state, {super.key, this.picker = pickPhoto});

  @override
  State<MyGymPage> createState() => _MyGymPageState();
}

class _MyGymPageState extends State<MyGymPage> {
  bool scanning = false;

  AppState get state => widget.state;

  Future<void> _scan() async {
    if (scanning) return;
    setState(() => scanning = true);
    String? message;
    try {
      final raw = await widget.picker(true);
      if (raw == null) return;
      final jpeg = prepareJpeg(raw);
      if (jpeg == null) {
        message = 'Tenhle formát fotky neumím přečíst. Zkus jinou.';
      } else {
        final result = await state.trainer.recognizeMachine(
          jpeg,
          builtInExercises,
        );
        switch (result) {
          case AiError(message: final m):
            message = m;
          case AiOk(:final value):
            final ids = [
              for (final m in value.matches)
                if (m.confidence >= 0.4) m.id,
            ];
            if (ids.isEmpty) {
              message = 'Stroj jsem nepoznal. Zkus fotku z větší dálky.';
            } else {
              await state.markGymHas(ids);
              message =
                  'Máš: ${ids.map((id) => state.exercise(id).name).join(', ')}';
            }
        }
      }
    } catch (_) {
      message = 'Fotku se nepodařilo načíst. Zkus to znovu.';
    } finally {
      if (mounted) setState(() => scanning = false);
    }
    if (mounted) showToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final p = context.palette;
        final text = Theme.of(context).textTheme;
        final answers = state.planAnswers ?? const PlanAnswers();
        final groups = gymMachinesByMuscle(answers.place);
        final count = groups.values.fold<int>(0, (s, l) => s + l.length);
        final have = groups.values
            .expand((l) => l)
            .where((e) => state.gymHas(e.id))
            .length;
        return LargeTitlePage(
          title: 'Moje posilovna',
          children: [
            const WhyLine(
              'Plán pak navrhuje jen cviky, které u tebe jdou odcvičit. '
              'Chybějící stroj nahradí podobný cvik.',
            ),
            const SizedBox(height: Space.xl),
            StaggerColumn(
              children: [
                for (final place in TrainingPlace.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: ChoiceCard(
                      icon: placeIcon(place),
                      label: place.label,
                      hint: place.hint,
                      selected: answers.place == place,
                      onTap: () => state.setGym(place: place),
                    ),
                  ),
              ],
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: Space.xl),
              Row(
                children: [
                  Expanded(child: Text('Stroje', style: text.titleLarge)),
                  Semantics(
                    label: 'Máš $have z $count strojů',
                    excludeSemantics: true,
                    child: Text(
                      '$have / $count',
                      style: text.titleMedium?.copyWith(
                        color: p.secondaryLabel,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.s),
              Text(
                'Vypni, co u vás chybí. Nebo stroj vyfoť a zapnu ho sám.',
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
              ),
              if (state.trainer.enabled) ...[
                const SizedBox(height: Space.m),
                SecondaryButton(
                  scanning ? 'Poznávám stroj…' : 'Nafotit stroj',
                  icon: Icons.photo_camera_outlined,
                  onPressed: scanning ? null : _scan,
                ),
              ],
              const SizedBox(height: Space.l),
              for (final MapEntry(key: muscle, value: list) in groups.entries)
                GroupedSection(
                  header: muscle,
                  children: [
                    for (final e in list)
                      GroupedRow(
                        leading: ExerciseThumb(e.id),
                        title: e.name,
                        subtitle: e.equipment.label,
                        verticalPadding: 0,
                        chevron: false,
                        onTap: () => state.toggleGymExercise(e.id),
                        trailing: Switch(
                          value: state.gymHas(e.id),
                          onChanged: (_) => state.toggleGymExercise(e.id),
                        ),
                      ),
                  ],
                ),
            ] else ...[
              const SizedBox(height: Space.xl),
              Text(
                'Bez strojů není co ladit. Plán bere cviky s vlastní váhou '
                'a tím, co máš doma.',
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
              ),
            ],
          ],
        );
      },
    );
  }
}

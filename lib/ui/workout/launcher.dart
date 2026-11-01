import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/splits.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../summary/summary_page.dart';
import 'builder_page.dart';
import 'workout_page.dart';

/// Je obrazovka tréninku (nebo jeho souhrn) otevřená? Sdílí ji Domů,
/// Trénink i lišta, ať dvojí klepnutí neotevře trénink dvakrát. Platí jen
/// pro navigátor, který ještě žije (zavřená aplikace pojistku uvolní).
NavigatorState? _openOn;

/// Otevře obrazovku tréninku přes celou aplikaci a po dokončení souhrn.
/// [onShown] se zavolá, jakmile je trénink nahoře (odemkne tlačítko).
Future<void> openWorkout(
  BuildContext context,
  AppState state, {
  VoidCallback? onShown,
}) async {
  final nav = Navigator.of(context, rootNavigator: true);
  if (_openOn != null && _openOn!.mounted) {
    onShown?.call();
    return;
  }
  _openOn = nav;
  try {
    final finished = nav.push<Workout>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkoutPage(state),
      ),
    );
    onShown?.call();
    final workout = await finished;
    if (workout != null && nav.mounted) {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => SummaryPage(state, workout, justFinished: true),
        ),
      );
    }
  } finally {
    if (identical(_openOn, nav)) _openOn = null;
  }
}

/// Společné spouštění tréninku pro Domů i Trénink: pojistka proti dvojímu
/// klepnutí, chybové hlášky a sestavení z partií.
mixin WorkoutLauncher<T extends StatefulWidget> on State<T> {
  AppState get state;

  /// Pojistka proti dvojímu klepnutí na start (dvě obrazovky tréninku).
  bool starting = false;
  bool _opening = false;

  Future<void> usePlan(PlanAnswers? answers) async {
    if (starting) return;
    setState(() => starting = true);
    try {
      await state.applyPlan(answers);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  /// Začne trénink ([start]) a otevře ho; prázdná funkce jen otevře rozepsaný.
  Future<void> runWorkout(Future<void> Function() start) async {
    if (starting) return;
    setState(() => starting = true);
    try {
      await start();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is StateError
              ? e.message
              : 'Trénink se nepodařilo začít. Zkus to znovu.',
        );
      }
      if (mounted) setState(() => starting = false);
      return;
    }
    if (!mounted) return;
    await openWorkout(
      context,
      state,
      onShown: () {
        if (mounted) setState(() => starting = false);
      },
    );
  }

  /// Sestavení tréninku z partií; hotový den rovnou začne.
  Future<void> buildWorkout([
    List<String> focuses = const [],
    List<String> avoid = const [],
  ]) async {
    if (_opening || starting) return;
    _opening = true;
    final SplitDay? day;
    try {
      day = await Navigator.push<SplitDay>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutBuilderPage(
            state,
            initialFocuses: focuses,
            avoidFocuses: avoid,
          ),
        ),
      );
    } finally {
      _opening = false;
    }
    final picked = day;
    if (picked == null || !mounted) return;
    await runWorkout(() => state.startPlanned(picked));
  }

  /// Jiný trénink než dnešní den plánu: volný, nebo sestavený z partií.
  Future<void> otherWorkout() async {
    final pick = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bolt_rounded),
                title: const Text('Volný trénink'),
                subtitle: const Text('Cviky přidáváš průběžně'),
                onTap: () => Navigator.pop(sheet, 0),
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Sestavit podle partií'),
                subtitle: const Text('Vybereš svaly, cviky navrhne aplikace'),
                onTap: () => Navigator.pop(sheet, 1),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (pick == 0) await runWorkout(state.startWorkout);
    if (pick == 1) await buildWorkout();
  }
}

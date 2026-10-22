import 'dart:convert';

import '../ai/trainer.dart';
import '../coach/plan_quiz.dart';
import '../coach/splits.dart';
import '../domain/bodyweight.dart';
import '../domain/models.dart';
import '../domain/nutrition.dart';
import '../domain/profile.dart';

/// Formát zálohy do souboru. Čistý Dart bez Flutteru.
///
/// Záloha obsahuje dokončené tréninky, vlastní cviky, váhu, výživový deník a nastavení
/// (ne souhlas s podmínkami – ten patří zařízení a člověku, ne souboru).
const backupFormat = 'gymzapisnik-backup';
const backupVersion = 1;

/// Klíče profilu, které jsou nastavením a patří do zálohy.
const backupSettingsKeys = {
  'restSeconds',
  'weightStep',
  'split',
  'theme',
  'accent',
  'look',
  'weekGoal',
  'proteinTarget',
  'kcalTarget',
  'pantry',
  'programs',
  'trainingDays',
  'plan',
  'coachChat',
};

class Backup {
  final DateTime exportedAt;
  final List<Workout> workouts;
  final List<Exercise> exercises;
  final Map<String, dynamic> settings;
  final List<BodyWeight> bodyweights;

  /// Výživový deník (nepovinný klíč; starší zálohy ho nemají).
  final List<FoodEntry> foods;

  const Backup({
    required this.exportedAt,
    required this.workouts,
    required this.exercises,
    required this.settings,
    this.bodyweights = const [],
    this.foods = const [],
  });
}

String encodeBackup(Backup backup) =>
    const JsonEncoder.withIndent(' ').convert({
      'format': backupFormat,
      'version': backupVersion,
      'exportedAt': backup.exportedAt.toUtc().toIso8601String(),
      'settings': backup.settings,
      'exercises': [for (final e in backup.exercises) e.toJson()],
      'workouts': [for (final w in backup.workouts) w.toJson()],
      'bodyweights': [for (final b in backup.bodyweights) b.toJson()],
      'foods': [for (final f in backup.foods) f.toJson()],
    });

/// Načte zálohu. Při neplatném souboru hodí [FormatException]
/// s českou zprávou pro uživatele.
Backup decodeBackup(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException {
    throw const FormatException('Soubor není platná záloha (chybný JSON).');
  }
  if (json is! Map || json['format'] != backupFormat) {
    throw const FormatException('Soubor není záloha Gym zápisníku.');
  }
  final version = json['version'];
  if (version is! int || version != backupVersion) {
    throw const FormatException(
      'Nepodporovaná verze zálohy. Zkontroluj verzi aplikace.',
    );
  }
  try {
    for (final raw in json['workouts'] as List? ?? const []) {
      final w = raw as Map;
      final start = DateTime.tryParse(w['startedAt'] as String? ?? '');
      final end = w['finishedAt'];
      if (start == null ||
          (end != null &&
              (end is! String ||
                  DateTime.tryParse(end) == null ||
                  DateTime.parse(end).isBefore(start)))) {
        throw const FormatException('Záloha obsahuje neplatný čas tréninku.');
      }
    }
    final workouts = [
      for (final w in json['workouts'] as List? ?? const [])
        Workout.fromJson(Map<String, dynamic>.from(w as Map)),
    ];
    final exercises = [
      for (final e in json['exercises'] as List? ?? const [])
        Exercise.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
    final bodyweights = [
      for (final b in json['bodyweights'] as List? ?? const [])
        BodyWeight.fromJson(Map<String, dynamic>.from(b as Map)),
    ];
    final foods = [
      for (final f in json['foods'] as List? ?? const [])
        FoodEntry.fromJson(Map<String, dynamic>.from(f as Map)),
    ];
    for (final f in foods) {
      if (parseDayKey(f.day) == null ||
          validateFood(
                name: f.name,
                amount: f.amount,
                basis: f.basis,
                values: f.values,
              ) !=
              null) {
        throw const FormatException('Záloha obsahuje neplatný záznam jídla.');
      }
    }
    final rawSettings = json['settings'];
    if (rawSettings != null && rawSettings is! Map) {
      throw const FormatException('Záloha obsahuje neplatné nastavení.');
    }
    if (rawSettings is Map) {
      for (final key in ['split', 'theme', 'accent', 'look']) {
        if (rawSettings[key] != null && rawSettings[key] is! String) {
          throw const FormatException('Záloha obsahuje neplatné nastavení.');
        }
      }
      final programs = rawSettings['programs'];
      if (programs != null &&
          (programs is! List ||
              programs.length > maxCustomPrograms ||
              programs.any((p) => SplitTemplate.tryCustom(p) == null) ||
              {for (final p in programs) (p as Map)['id']}.length !=
                  programs.length)) {
        throw const FormatException('Záloha obsahuje neplatný program.');
      }
      final days = rawSettings['trainingDays'];
      if (days != null &&
          (days is! List ||
              days.any((d) => d is! num || d < 1 || d > 7 || d != d.toInt()))) {
        throw const FormatException('Záloha obsahuje neplatné dny tréninku.');
      }
      for (final key in ['restSeconds', 'weekGoal', 'weightStep']) {
        final value = rawSettings[key];
        if (value != null && (value is! num || !value.isFinite)) {
          throw const FormatException('Záloha obsahuje neplatné nastavení.');
        }
      }
      final plan = rawSettings['plan'];
      if (plan != null && PlanAnswers.tryParse(plan) == null) {
        throw const FormatException('Záloha obsahuje neplatný plán.');
      }
      final chat = rawSettings['coachChat'];
      if (chat != null &&
          (chat is! List || chat.any((m) => ChatMessage.tryParse(m) == null))) {
        throw const FormatException(
          'Záloha obsahuje neplatný chat s trenérem.',
        );
      }
      final step = rawSettings['weightStep'];
      if (step != null && !weightSteps.contains(step)) {
        throw const FormatException('Záloha obsahuje neplatný krok váhy.');
      }
    }
    final ids = <String>{};
    for (final id in [
      ...workouts.map((w) => w.id),
      ...exercises.map((e) => e.id),
      ...bodyweights.map((b) => b.id),
      ...foods.map((f) => f.id),
    ]) {
      if (id.trim().isEmpty || id == Profile.id || !ids.add(id)) {
        throw const FormatException(
          'Záloha obsahuje prázdné nebo duplicitní ID.',
        );
      }
    }
    return Backup(
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      // Rozepsaný trénink do obnovy nepatří.
      workouts: workouts.where((w) => w.finished).toList(),
      exercises: exercises,
      bodyweights: bodyweights,
      foods: foods,
      settings: {
        if (rawSettings is Map)
          for (final e in rawSettings.entries)
            if (backupSettingsKeys.contains(e.key)) e.key as String: e.value,
      },
    );
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('Záloha je poškozená.');
  }
}

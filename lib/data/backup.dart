import 'dart:convert';

import '../domain/models.dart';

/// Formát zálohy do souboru. Čistý Dart bez Flutteru.
///
/// Záloha obsahuje dokončené tréninky, vlastní cviky a nastavení
/// (ne souhlas s podmínkami – ten patří zařízení a člověku, ne souboru).
const backupFormat = 'gymzapisnik-backup';
const backupVersion = 1;

/// Klíče profilu, které jsou nastavením a patří do zálohy.
const backupSettingsKeys = {'restSeconds', 'split', 'theme'};

class Backup {
  final DateTime exportedAt;
  final List<Workout> workouts;
  final List<Exercise> exercises;
  final Map<String, dynamic> settings;

  const Backup({
    required this.exportedAt,
    required this.workouts,
    required this.exercises,
    required this.settings,
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
  if (version is! num || version > backupVersion) {
    throw const FormatException(
      'Záloha je z novější verze aplikace. Nejdřív aplikaci aktualizuj.',
    );
  }
  try {
    final workouts = [
      for (final w in json['workouts'] as List? ?? const [])
        Workout.fromJson(Map<String, dynamic>.from(w as Map)),
    ];
    final exercises = [
      for (final e in json['exercises'] as List? ?? const [])
        Exercise.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
    final rawSettings = json['settings'];
    return Backup(
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      // Rozepsaný trénink do obnovy nepatří.
      workouts: workouts.where((w) => w.finished).toList(),
      exercises: exercises,
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

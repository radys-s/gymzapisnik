import 'package:flutter/foundation.dart';

/// Jedna zachycená chyba.
class DiagnosticEntry {
  final DateTime at;

  /// Kde chyba vznikla (např. „načtení“, „Flutter“).
  final String where;
  final String message;
  final String? stack;

  const DiagnosticEntry({
    required this.at,
    required this.where,
    required this.message,
    this.stack,
  });

  @override
  String toString() =>
      '${at.toIso8601String()} [$where] $message${stack == null ? '' : '\n$stack'}';
}

/// Posledních [max] chyb za běh aplikace, jen v paměti zařízení. Bez nich
/// by nezachycená chyba tiše zmizela a tester by neměl co poslat.
abstract final class Diagnostics {
  static const max = 20;

  static final _entries = <DiagnosticEntry>[];

  /// Ozve se po každém novém záznamu (obrazovka Diagnostika).
  static final changes = ValueNotifier<int>(0);

  /// Nejnovější první.
  static List<DiagnosticEntry> get entries =>
      List.unmodifiable(_entries.reversed);

  static void record(Object error, {StackTrace? stack, String where = 'app'}) {
    final text = stack?.toString().split('\n').take(8).join('\n');
    _entries.add(
      DiagnosticEntry(
        at: DateTime.now(),
        where: where,
        message: error.toString(),
        stack: text == null || text.trim().isEmpty ? null : text,
      ),
    );
    if (_entries.length > max) _entries.removeAt(0);
    changes.value++;
    debugPrint('[$where] $error');
  }

  static void clear() {
    _entries.clear();
    changes.value++;
  }

  /// Text pro zkopírování a poslání vývojáři.
  static String report({required String version}) => [
    'Gym zápisník $version',
    for (final e in _entries.reversed) e.toString(),
  ].join('\n\n');
}

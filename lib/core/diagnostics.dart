import 'dart:async';

import 'package:flutter/foundation.dart';

/// Jedna zachycená chyba.
class DiagnosticEntry {
  final DateTime at;

  /// Kde chyba vznikla (např. „načtení“, „Flutter“).
  final String where;
  final String message;
  final String? stack;

  /// Kolikrát za sebou přišla stejná chyba (chyba kreslení se opakuje
  /// každý snímek a jinak by vytlačila původní příčinu).
  final int count;

  const DiagnosticEntry({
    required this.at,
    required this.where,
    required this.message,
    this.stack,
    this.count = 1,
  });

  @override
  String toString() =>
      '${at.toIso8601String()} [$where]${count > 1 ? ' ×$count' : ''} '
      '$message${stack == null ? '' : '\n$stack'}';
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

  static const maxMessage = 300;

  static bool _recording = false;
  static bool _notifyQueued = false;

  /// Nikdy nevyhodí: volá se z obsluhy chyb, kde by další chyba smazala
  /// původní. Chyba vzniklá během záznamu (i z posluchače) se zahodí.
  static void record(Object error, {StackTrace? stack, String where = 'app'}) {
    if (_recording) return;
    _recording = true;
    try {
      var message = _describe(error);
      if (message.length > maxMessage) {
        message = '${message.substring(0, maxMessage)}…';
      }
      final text = stack?.toString().split('\n').take(8).join('\n');
      final last = _entries.isEmpty ? null : _entries.last;
      if (last != null && last.where == where && last.message == message) {
        _entries[_entries.length - 1] = DiagnosticEntry(
          at: DateTime.now(),
          where: where,
          message: message,
          stack: last.stack,
          count: last.count + 1,
        );
      } else {
        _entries.add(
          DiagnosticEntry(
            at: DateTime.now(),
            where: where,
            message: message,
            stack: text == null || text.trim().isEmpty ? null : text,
          ),
        );
        if (_entries.length > max) _entries.removeAt(0);
      }
      _notify();
      debugPrint('[$where] $message');
      if (kDebugMode && stack != null) debugPrintStack(stackTrace: stack);
    } catch (_) {
      // Záznam chyby nesmí shodit obsluhu chyb.
    } finally {
      _recording = false;
    }
  }

  static String _describe(Object error) {
    try {
      return error.toString();
    } catch (_) {
      return error.runtimeType.toString();
    }
  }

  /// Chyba často přijde uprostřed kreslení; posluchač (obrazovka) se
  /// proto dozví až po něm, ne synchronně uvnitř buildu.
  static void _notify() {
    if (_notifyQueued) return;
    _notifyQueued = true;
    scheduleMicrotask(() {
      _notifyQueued = false;
      // Chyba posluchače by přes globální obsluhu volala záznam znovu.
      _recording = true;
      try {
        changes.value++;
      } catch (_) {
      } finally {
        _recording = false;
      }
    });
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

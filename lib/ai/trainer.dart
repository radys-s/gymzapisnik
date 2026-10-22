/// AI trenér: fotka stroje -> cviky z katalogu a chat s trenérem.
///
/// Stejná proxy jako kouč ledničky (`worker/`), jen jiné cesty.
library;

import 'dart:typed_data';

import '../domain/models.dart';
import 'fridge_coach.dart';

/// Kolik cviků z katalogu nejvíc posíláme proxy (stejný limit jako Worker).
const maxMachineCatalog = 150;

/// Kolik zpráv chatu nejvíc posíláme (stejný limit jako Worker).
const maxChatSent = 12;

/// Nejdelší zpráva uživatele.
const maxChatMessage = 1000;

/// Nejdelší souhrn tréninků v JSON (stejný limit jako Worker).
const maxCoachContext = 6000;

/// Kolik zpráv chatu si aplikace pamatuje.
const maxCoachChat = 30;

class MachineMatch {
  final String id;

  /// Jistota modelu 0–1.
  final double confidence;
  const MachineMatch(this.id, this.confidence);
}

class MachineResult {
  /// Co AI na fotce vidí (např. „Leg press“), `null` = nepoznala.
  final String? machine;

  /// Nejvýš 3 cviky, nejjistější první. Jen ID, která aplikace zná.
  final List<MachineMatch> matches;
  const MachineResult(this.machine, this.matches);
}

/// Odpověď proxy; [known] jsou ID odeslaná v požadavku. Neznámá ID a
/// duplicity zahodí, takže si model nemůže vymyslet cvik.
MachineResult parseMachine(Object? json, Set<String> known) {
  if (json is! Map) throw const FormatException('Chybí odpověď.');
  final raw = json['matches'];
  if (raw is! List) throw const FormatException('Chybí cviky.');
  final seen = <String>{};
  final matches = <MachineMatch>[];
  for (final m in raw) {
    if (m is! Map) continue;
    final id = m['id'];
    if (id is! String || !known.contains(id) || !seen.add(id)) continue;
    final c = m['confidence'];
    final conf = c is num && c.isFinite ? c.clamp(0, 1).toDouble() : 0.5;
    matches.add(MachineMatch(id, conf));
  }
  matches.sort((a, b) => b.confidence.compareTo(a.confidence));
  final machine = json['machine'];
  return MachineResult(
    machine is String && machine.trim().isNotEmpty ? machine.trim() : null,
    matches.take(3).toList(),
  );
}

enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime at;
  const ChatMessage(this.role, this.content, this.at);

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    'at': at.toUtc().toIso8601String(),
  };

  /// Ze zálohy nebo profilu; neplatné vrací `null`.
  static ChatMessage? tryParse(Object? json) {
    if (json is! Map) return null;
    final role = ChatRole.values.where((r) => r.name == json['role']);
    final content = json['content'];
    final at = DateTime.tryParse('${json['at']}');
    if (role.isEmpty || content is! String || content.trim().isEmpty) {
      return null;
    }
    return ChatMessage(
      role.first,
      content.length > 2000 ? content.substring(0, 2000) : content,
      (at ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)).toLocal(),
    );
  }
}

/// Rozhraní AI trenéra (v testech jde nahradit falešným).
abstract interface class TrainerAi {
  bool get enabled;

  /// Fotka stroje (JPEG) -> 1–3 cviky z [catalog].
  Future<AiResult<MachineResult>> recognizeMachine(
    Uint8List jpeg,
    List<Exercise> catalog,
  );

  /// Odpověď trenéra na poslední zprávu v [messages].
  Future<AiResult<String>> ask(
    List<ChatMessage> messages,
    Map<String, dynamic> context, {
    required bool adult,
  });
}

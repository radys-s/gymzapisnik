/// Klient AI kouče: fotka ledničky -> potraviny, potraviny -> návrhy jídel.
///
/// Volá vlastní proxy (`worker/`), ne přímo model. Aplikace nemá žádný klíč;
/// limit hlídá proxy podle náhodného ID instalace.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/food_table.dart';
import '../domain/models.dart';
import '../domain/nutrition.dart';
import 'trainer.dart';

/// Potravina v ledničce / spíži. [amount] a [unit] (`g`, `ml`, `ks`) jsou
/// volitelné.
class PantryItem {
  final String name;
  final double? amount;
  final String? unit;

  const PantryItem(this.name, {this.amount, this.unit});

  static const units = ['g', 'ml', 'ks'];

  /// Z JSON; `null`, když chybí název.
  static PantryItem? tryParse(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final amount = json['amount'];
    final unit = json['unit'];
    final a = amount is num && amount.isFinite && amount > 0
        ? amount.toDouble()
        : null;
    return PantryItem(
      name.trim().length > 60 ? name.trim().substring(0, 60) : name.trim(),
      amount: a,
      unit: a != null && units.contains(unit) ? unit as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
  };

  IngredientAmount get asIngredient => (name: name, amount: amount, unit: unit);
}

String pantryKey(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Nový potvrzený údaj nahradí množství; neurčitý údaj nezahodí známé množství.
List<PantryItem> mergePantry(
  List<PantryItem> current,
  List<PantryItem> updates,
) {
  final byName = <String, PantryItem>{};
  for (final item in [...current, ...updates]) {
    final key = pantryKey(item.name);
    if (key.isEmpty) continue;
    final old = byName[key];
    byName[key] = item.amount == null && old?.amount != null ? old! : item;
  }
  return byName.values.toList();
}

/// Odkud je odhad maker.
enum EstimateSource { table, ai }

class MealIdea {
  final String title;
  final int minutes;
  final List<PantryItem> ingredients;
  final List<String> steps;

  /// Odhad na celou porci.
  final Nutrition estimate;
  final EstimateSource source;

  const MealIdea({
    required this.title,
    required this.minutes,
    required this.ingredients,
    required this.steps,
    required this.estimate,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'minutes': minutes,
    'ingredients': [for (final i in ingredients) i.toJson()],
    'steps': steps,
    'estimate': estimate.toJson(),
  };
}

class MealContext {
  final bool trainingToday;
  final double? eatenKcal;
  final double? eatenProtein;
  final double? proteinLeft;
  final int maxMinutes;
  final bool adult;

  const MealContext({
    required this.trainingToday,
    required this.maxMinutes,
    required this.adult,
    this.eatenKcal,
    this.eatenProtein,
    this.proteinLeft,
  });

  Map<String, dynamic> toJson() => {
    'trainingToday': trainingToday,
    'eatenToday': {
      // Nezletilým se kalorie neposílají.
      'kcal': adult ? eatenKcal : null,
      'protein': eatenProtein,
    },
    'proteinLeft': proteinLeft,
    'maxMinutes': maxMinutes,
    'adult': adult,
  };
}

enum AiErrorKind { disabled, offline, quota, busy, failed }

sealed class AiResult<T> {
  const AiResult();
}

class AiOk<T> extends AiResult<T> {
  final T value;
  const AiOk(this.value);
}

class AiError<T> extends AiResult<T> {
  final AiErrorKind kind;
  final String message;
  const AiError(this.kind, this.message);
}

abstract interface class FridgeCoach {
  /// Je AI k dispozici (nastavená adresa proxy)?
  bool get enabled;

  Future<AiResult<List<PantryItem>>> scanFridge(Uint8List jpeg);

  Future<AiResult<List<MealIdea>>> suggestMeals(
    List<PantryItem> items,
    MealContext context,
  );
}

abstract interface class CancellableFridgeCoach {
  void cancelPending();
}

/// Návrhy z odpovědi proxy. Makra přednostně z místní tabulky, jinak odhad AI.
List<MealIdea> parseMeals(Object? json) {
  final meals = json is Map ? json['meals'] : null;
  if (meals is! List) return const [];
  final out = <MealIdea>[];
  for (final m in meals) {
    if (m is! Map) continue;
    final title = m['title'];
    final minutes = m['minutes'];
    final steps = m['steps'];
    final est = m['estimate'];
    if (title is! String ||
        title.trim().isEmpty ||
        minutes is! num ||
        !minutes.isFinite ||
        minutes < 1 ||
        minutes > 240 ||
        steps is! List ||
        steps.isEmpty ||
        est is! Map) {
      continue;
    }
    final ingredients = [
      for (final i
          in (m['ingredients'] is List ? m['ingredients'] as List : []))
        ?PantryItem.tryParse(i),
    ];
    if (ingredients.isEmpty) continue;
    double? n(Object? v) =>
        v is num && v.isFinite && v >= 0 ? v.toDouble() : null;
    final table = tableEstimate([for (final i in ingredients) i.asIngredient]);
    out.add(
      MealIdea(
        title: title,
        minutes: minutes.round(),
        ingredients: ingredients,
        steps: [
          for (final s in steps)
            if (s is String) s,
        ],
        estimate:
            table ??
            Nutrition(
              kcal: n(est['kcal']),
              protein: n(est['protein']),
              carbs: n(est['carbs']),
              fat: n(est['fat']),
            ),
        source: table == null ? EstimateSource.ai : EstimateSource.table,
      ),
    );
  }
  return out;
}

List<PantryItem> parseItems(Object? json) {
  final items = json is Map ? json['items'] : null;
  if (items is! List) throw const FormatException('Chybí seznam potravin.');
  final parsed = [for (final i in items) ?PantryItem.tryParse(i)];
  if (parsed.length != items.length) {
    throw const FormatException('Neplatná potravina.');
  }
  return parsed;
}

/// Chybová odpověď proxy na výsledek pro UI (zpráva je česky z proxy).
AiError<T> errorFromResponse<T>(int status, String body) {
  String? message;
  String? code;
  try {
    final json = jsonDecode(body);
    final error = json is Map ? json['error'] : null;
    if (error is Map) {
      final m = error['message'];
      final c = error['code'];
      message = m is String && m.isNotEmpty ? m : null;
      code = c is String ? c : null;
    }
  } on FormatException {
    // Prázdné nebo nečitelné tělo: obecná zpráva níž.
  }
  if (code == 'service_busy' || status == 503) {
    return AiError(
      AiErrorKind.busy,
      message ?? 'Služba je teď vytížená. Zkus to za chvíli.',
    );
  }
  if (status == 429 || code == 'quota_install' || code == 'quota_global') {
    return AiError(
      AiErrorKind.quota,
      message ?? 'Dnešní limit AI je vyčerpaný. Zkus to zítra.',
    );
  }
  return AiError(
    AiErrorKind.failed,
    message ?? 'AI teď nefunguje (chyba $status). Zkus to později.',
  );
}

class HttpFridgeCoach
    implements FridgeCoach, CancellableFridgeCoach, TrainerAi {
  HttpFridgeCoach({
    required this.baseUrl,
    required this.installId,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final String baseUrl;

  /// Vrací ID instalace (vytvoří ho při prvním použití).
  final Future<String> Function() installId;
  final Duration timeout;
  final http.Client _client;
  final _pending = <Completer<void>>{};

  @override
  void cancelPending() {
    for (final request in _pending.toList()) {
      if (!request.isCompleted) request.complete();
    }
  }

  @override
  bool get enabled => baseUrl.isNotEmpty;

  Future<AiResult<T>> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Object? json) parse,
    bool Function(T value) valid,
  ) async {
    if (!enabled) {
      return const AiError(
        AiErrorKind.disabled,
        'AI v této verzi aplikace zatím není zapnutá.',
      );
    }
    final abort = Completer<void>();
    _pending.add(abort);
    final String id;
    try {
      id = await installId();
    } catch (_) {
      _pending.remove(abort);
      return const AiError(
        AiErrorKind.failed,
        'Identifikátor aplikace se nepodařilo uložit. Zkus to znovu; '
        'aplikaci zatím nezavírej.',
      );
    }
    try {
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final request =
          http.AbortableRequest(
              'POST',
              Uri.parse('$base$path'),
              abortTrigger: abort.future,
            )
            ..headers.addAll({
              'Content-Type': 'application/json',
              'X-Install-Id': id,
            })
            ..body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode != 200) {
        return errorFromResponse(response.statusCode, text);
      }
      final value = parse(jsonDecode(text));
      if (!valid(value)) {
        return const AiError(
          AiErrorKind.failed,
          'AI vrátila nečitelnou odpověď. Zkus to znovu.',
        );
      }
      return AiOk(value);
    } on TimeoutException {
      return const AiError(
        AiErrorKind.offline,
        'AI neodpověděla včas. Zkus to znovu.',
      );
    } on FormatException {
      return const AiError(
        AiErrorKind.failed,
        'AI vrátila nečitelnou odpověď. Zkus to znovu.',
      );
    } catch (_) {
      return const AiError(
        AiErrorKind.offline,
        'K AI se nepodařilo připojit. Zkontroluj internet; na webu může '
        'připojení blokovat i nastavení serveru.',
      );
    } finally {
      _pending.remove(abort);
      if (!abort.isCompleted) abort.complete();
    }
  }

  @override
  Future<AiResult<List<PantryItem>>> scanFridge(Uint8List jpeg) => _post(
    '/v1/fridge',
    {'image': base64Encode(jpeg)},
    parseItems,
    (_) => true,
  );

  @override
  Future<AiResult<List<MealIdea>>> suggestMeals(
    List<PantryItem> items,
    MealContext context,
  ) => _post(
    '/v1/meals',
    {
      'items': [for (final i in items.take(40)) i.toJson()],
      'context': context.toJson(),
    },
    parseMeals,
    (meals) => meals.isNotEmpty,
  );

  @override
  Future<AiResult<MachineResult>> recognizeMachine(
    Uint8List jpeg,
    List<Exercise> catalog,
  ) {
    final sent = catalog.take(maxMachineCatalog).toList();
    final known = {for (final e in sent) e.id};
    return _post(
      '/v1/machine',
      {
        'image': base64Encode(jpeg),
        'exercises': [
          for (final e in sent) {'id': e.id, 'name': e.name},
        ],
      },
      (json) => parseMachine(json, known),
      (_) => true,
    );
  }

  @override
  Future<AiResult<String>> ask(
    List<ChatMessage> messages,
    Map<String, dynamic> context, {
    required bool adult,
  }) {
    final recent = messages.length > maxChatSent
        ? messages.sublist(messages.length - maxChatSent)
        : messages;
    if (recent.isEmpty || recent.last.role != ChatRole.user) {
      return Future.value(
        const AiError(AiErrorKind.failed, 'Chybí otázka pro trenéra.'),
      );
    }
    if (jsonEncode(context).length > maxCoachContext) {
      return Future.value(
        const AiError(
          AiErrorKind.failed,
          'Souhrn tréninků je moc dlouhý. Zkus to znovu.',
        ),
      );
    }
    return _post(
      '/v1/coach',
      {
        'messages': [
          for (final m in recent)
            {
              'role': m.role.name,
              'content': m.content.length > maxChatMessage
                  ? m.content.substring(0, maxChatMessage)
                  : m.content,
            },
        ],
        'context': context,
        'adult': adult,
      },
      (json) => json is Map && json['reply'] is String
          ? (json['reply'] as String).trim()
          : throw const FormatException('Chybí odpověď.'),
      (reply) => reply.isNotEmpty,
    );
  }
}

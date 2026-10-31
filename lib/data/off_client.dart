/// Hledání produktu podle čárového kódu v Open Food Facts (API v3).
///
/// Dokumentace: https://openfoodfacts.github.io/openfoodfacts-server/api/
/// Čtení nepotřebuje přihlášení, jen vlastní User-Agent `Aplikace/verze (kontakt)`.
/// Limit pro čtení produktu je 15 požadavků za minutu.
/// Data jsou pod licencí ODbL, mohou být nepřesná: uživatel je před uložením
/// potvrdí a upraví.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/version.dart';
import '../domain/nutrition.dart';

/// Produkt z databáze; hodnoty `null` = v databázi chybí.
class OffProduct {
  final String barcode;
  final String name;
  final String? brand;

  /// Hodnoty na 100 g / 100 ml.
  final Nutrition? per100;

  /// Hodnoty na porci, když je zdroj uvádí.
  final Nutrition? perServing;

  /// Velikost porce v g/ml, když ji zdroj uvádí.
  final double? servingAmount;

  /// Popis porce z obalu (např. „30 g“).
  final String? servingLabel;

  const OffProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.per100,
    this.perServing,
    this.servingAmount,
    this.servingLabel,
  });
}

sealed class LookupResult {
  const LookupResult();
}

class LookupFound extends LookupResult {
  final OffProduct product;
  const LookupFound(this.product);
}

class LookupNotFound extends LookupResult {
  const LookupNotFound();
}

/// Síť nebo server nejsou k dispozici, nebo odpověď nedává smysl.
class LookupFailed extends LookupResult {
  final String message;
  const LookupFailed(this.message);
}

abstract interface class ProductLookup {
  Future<LookupResult> byBarcode(String barcode);
}

final offUserAgent =
    'GymZapisnik/$appVersion '
    '(${feedbackContact.isEmpty ? projectUrl : feedbackContact})';

class OffClient implements ProductLookup {
  OffClient({
    http.Client? client,
    this.host = 'world.openfoodfacts.org',
    this.timeout = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final String host;
  final Duration timeout;
  final DateTime Function() _clock;
  final List<DateTime> _recent = [];

  static const _fields =
      'code,product_name,product_name_cs,brands,nutriments,'
      'serving_size,serving_quantity,nutrition_data_per';

  /// Nejvýš 10 dotazů za minutu na zařízení (limit OFF je 15).
  bool _allow() {
    final now = _clock();
    _recent.removeWhere((t) => now.difference(t) >= const Duration(minutes: 1));
    if (_recent.length >= 10) return false;
    _recent.add(now);
    return true;
  }

  @override
  Future<LookupResult> byBarcode(String barcode) async {
    if (!validBarcode(barcode)) {
      return const LookupFailed('Čárový kód nemá správný formát.');
    }
    if (!_allow()) {
      return const LookupFailed('Moc dotazů za sebou. Zkus to za minutu.');
    }
    final uri = Uri.https(host, '/api/v3/product/$barcode', {
      'fields': _fields,
    });
    try {
      final response = await _client
          .get(
            uri,
            // Prohlížeč User-Agent měnit nesmí; X-User-Agent projde CORS.
            headers: {'User-Agent': offUserAgent, 'X-User-Agent': offUserAgent},
          )
          .timeout(timeout);
      return parseLookupResponse(
        barcode,
        response.statusCode,
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
    } on TimeoutException {
      return const LookupFailed('Databáze neodpověděla včas.');
    } catch (_) {
      return const LookupFailed(
        'Databáze není dostupná (zkontroluj internet).',
      );
    }
  }
}

/// Zpracuje odpověď API; čistá funkce kvůli testům.
LookupResult parseLookupResponse(String barcode, int status, String body) {
  Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    json = null;
  }
  final map = json is Map ? json : null;
  if (status == 404 ||
      (map != null &&
          (map['result'] is Map &&
                  (map['result'] as Map)['id'] == 'product_not_found' ||
              map['status'] == 'failure' && map['product'] == null))) {
    return const LookupNotFound();
  }
  if (status != 200 || map == null) {
    return const LookupFailed('Databáze vrátila neočekávanou odpověď.');
  }
  final product = map['product'];
  if (product is! Map) return const LookupNotFound();
  final parsed = parseOffProduct(barcode, Map<String, dynamic>.from(product));
  return parsed == null ? const LookupNotFound() : LookupFound(parsed);
}

double? _value(Object? v) {
  final n = v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
  return n != null && n.isFinite && n >= 0 ? n : null;
}

Nutrition? _nutrition(Map n, String suffix) {
  var kcal = _value(n['energy-kcal$suffix']);
  // Starší záznamy mívají jen kJ.
  final kj = _value(n['energy-kj$suffix']) ?? _value(n['energy$suffix']);
  kcal ??= kj == null ? null : kj / 4.184;
  final result = Nutrition(
    kcal: kcal,
    protein: _value(n['proteins$suffix']),
    carbs: _value(n['carbohydrates$suffix']),
    fat: _value(n['fat$suffix']),
  );
  return result.isEmpty ? null : result;
}

/// Z produktu vytáhne název a hodnoty. `null`, když nemá ani název, ani
/// hodnoty (nic, co by šlo uložit).
OffProduct? parseOffProduct(String barcode, Map<String, dynamic> p) {
  final rawName = (p['product_name_cs'] as String?)?.trim().isNotEmpty == true
      ? p['product_name_cs'] as String
      : (p['product_name'] as String? ?? '');
  final name = rawName.trim();
  final brandRaw = (p['brands'] as String? ?? '').split(',').first.trim();
  final nutriments = p['nutriments'];
  final n = nutriments is Map ? nutriments : const {};
  final per100 = _nutrition(n, '_100g');
  final perServing = _nutrition(n, '_serving');
  if (name.isEmpty && per100 == null && perServing == null) return null;
  final servingAmount = _value(p['serving_quantity']);
  final label = (p['serving_size'] as String?)?.trim();
  return OffProduct(
    barcode: barcode,
    name: name,
    brand: brandRaw.isEmpty ? null : brandRaw,
    per100: per100,
    perServing: perServing,
    servingAmount: servingAmount != null && servingAmount > 0
        ? servingAmount
        : null,
    servingLabel: label == null || label.isEmpty ? null : label,
  );
}

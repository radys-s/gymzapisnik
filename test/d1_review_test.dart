import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/ai/photo.dart';
import 'package:gymzapisnik/domain/food_table.dart';
import 'package:gymzapisnik/ui/nutrition/fridge_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

void main() {
  test('unknown unit is not silently converted to pieces', () {
    expect(gramsOf(findFood('chléb')!, 200, null), isNull);
    expect(
      itemAmount(const PantryItem('chléb', amount: 200)),
      '200 (jednotka neznámá)',
    );
  });

  test(
    'small JPEG with large dimensions is resized and invalid JPEG rejected',
    () {
      final large = img.Image(width: 2048, height: 1024);
      final jpeg = Uint8List.fromList(img.encodeJpg(large));
      expect(jpeg.length, lessThan(maxPhotoBytes ~/ 2));
      final prepared = prepareJpeg(jpeg)!;
      expect(img.decodeJpg(prepared)!.width, maxPhotoSide);
      expect(prepareJpeg(Uint8List.fromList([255, 216, 255, 0])), isNull);
    },
  );

  test('invalid scan response is not reported as an empty fridge', () async {
    final coach = HttpFridgeCoach(
      baseUrl: 'https://example.test',
      installId: () async => '0b9f5c2e-6f1a-4c3d-9e8b-1a2b3c4d5e6f',
      client: MockClient((_) async => http.Response('{"wrong":[]}', 200)),
    );
    expect(await coach.scanFridge(Uint8List(3)), isA<AiError>());
  });

  test(
    'local install-id save failure is not reported as a network error',
    () async {
      var calls = 0;
      final coach = HttpFridgeCoach(
        baseUrl: 'https://example.test',
        installId: () async => throw StateError('disk full'),
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      final result = await coach.scanFridge(Uint8List(3)) as AiError;
      expect(result.kind, AiErrorKind.failed);
      expect(result.message, contains('uložit'));
      expect(calls, 0);
    },
  );
}

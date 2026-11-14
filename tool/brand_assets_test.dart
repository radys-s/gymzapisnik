// Renders the app logo into every icon file from the same painter the app
// uses. Run after changing lib/ui/design/brand.dart:
//
//   flutter test tool/brand_assets_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/design/brand.dart';

/// PNG bytes of the logo at [px] pixels.
Future<Uint8List> _png(int px, BrandPainter painter, {Color? matte}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(px.toDouble(), px.toDouble());
  if (matte != null) {
    canvas.drawRect(Offset.zero & size, Paint()..color = matte);
  }
  painter.paint(canvas, size);
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('write logo files', (tester) async {
    const ink = Color(0xFF0B0C14);
    // Full square: iOS and the web mask the corners themselves.
    const icon = BrandPainter(rounded: false);
    // Maskable web icon: the mark stays inside the 80 % safe circle.
    const maskable = BrandPainter(rounded: false, scale: 0.78);
    // Launch screens: the same rounded plate the app shows while loading.
    const launch = BrandPainter();
    // Android adaptive foreground: mark only, inside the 66 dp circle.
    const foreground = BrandPainter(plate: false, scale: 0.62);
    final out = Platform.environment['BRAND_OUT'];
    final root = out ?? Directory.current.path;
    final files = <String, (int, BrandPainter, Color?)>{};

    final ios = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final name = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$');
    for (final f in ios.listSync().whereType<File>()) {
      final m = name.firstMatch(f.path);
      if (m == null) continue;
      final px = (double.parse(m[1]!) * int.parse(m[2]!)).round();
      files[f.path] = (px, icon, ink);
    }
    const launchDir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    files['$launchDir/LaunchImage.png'] = (96, launch, null);
    files['$launchDir/LaunchImage@2x.png'] = (192, launch, null);
    files['$launchDir/LaunchImage@3x.png'] = (288, launch, null);
    const dpi = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0};
    for (final e in {...dpi, 'xxxhdpi': 4.0}.entries) {
      final dir = 'android/app/src/main/res/mipmap-${e.key}';
      if (!Directory(dir).existsSync()) continue;
      files['$dir/ic_launcher.png'] = ((48 * e.value).round(), icon, ink);
      files['$dir/ic_launcher_foreground.png'] = (
        (108 * e.value).round(),
        foreground,
        null,
      );
      files['android/app/src/main/res/drawable-${e.key}/splash_mark.png'] = (
        (96 * e.value).round(),
        launch,
        null,
      );
    }
    files['web/icons/Icon-192.png'] = (192, icon, ink);
    files['web/icons/Icon-512.png'] = (512, icon, ink);
    files['web/icons/Icon-maskable-192.png'] = (192, maskable, ink);
    files['web/icons/Icon-maskable-512.png'] = (512, maskable, ink);
    files['web/icons/apple-touch-icon.png'] = (180, icon, ink);
    files['web/icons/splash-mark.png'] = (96, launch, null);
    files['web/favicon.png'] = (64, launch, null);

    await tester.runAsync(() async {
      for (final e in files.entries) {
        final (px, painter, matte) = e.value;
        final file = File('$root/${e.key}');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(await _png(px, painter, matte: matte));
      }
    });
    expect(files, isNotEmpty);
  });
}

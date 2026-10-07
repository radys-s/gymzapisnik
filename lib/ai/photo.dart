/// Příprava fotky pro AI: JPEG, delší strana nejvýš 1024 px, do ~1 MB.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

const maxPhotoSide = 1024;
const maxPhotoBytes = 1000000;

bool _isJpeg(Uint8List b) =>
    b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

/// Vrací JPEG připravený k odeslání, nebo `null`, když fotku nejde přečíst.
///
/// Malý JPEG (už zmenšený výběrem fotky) projde beze změny; jinak se
/// dekóduje, zmenší a znovu uloží.
Uint8List? prepareJpeg(Uint8List bytes) {
  if (_isJpeg(bytes) && bytes.length <= maxPhotoBytes ~/ 2) return bytes;
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    // Poškozený nebo neznámý formát: dekodér umí hodit i RangeError.
    decoded = null;
  }
  if (decoded == null) return null;
  final oriented = img.bakeOrientation(decoded);
  final longest = oriented.width > oriented.height
      ? oriented.width
      : oriented.height;
  final resized = longest <= maxPhotoSide
      ? oriented
      : oriented.width >= oriented.height
      ? img.copyResize(oriented, width: maxPhotoSide)
      : img.copyResize(oriented, height: maxPhotoSide);
  for (final quality in [80, 65, 50]) {
    final out = img.encodeJpg(resized, quality: quality);
    if (out.length <= maxPhotoBytes) return out;
  }
  return null;
}

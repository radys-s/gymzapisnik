/// Příprava fotky pro AI: JPEG, delší strana nejvýš 1024 px, do ~1 MB.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

const maxPhotoSide = 1024;
const maxPhotoBytes = 1000000;

/// Vrací JPEG připravený k odeslání, nebo `null`, když fotku nejde přečíst.
///
/// I malý soubor může mít velké rozměry nebo být poškozený. Vždy se
/// dekóduje, ověří rozměry, zmenší a znovu uloží.
Uint8List? prepareJpeg(Uint8List bytes) {
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

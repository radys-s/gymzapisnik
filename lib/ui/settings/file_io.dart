import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Ukládání a otevírání souborů. V testech jde nahradit.
abstract class FileIo {
  /// Uloží text; `false` = uživatel ukládání zrušil.
  Future<bool> saveText(String name, String content, String mimeType);

  /// Otevře soubor a vrátí jeho text; `null` = zrušeno.
  Future<String?> pickText(List<String> extensions);
}

class PickerFileIo implements FileIo {
  const PickerFileIo();

  @override
  Future<bool> saveText(String name, String content, String mimeType) async {
    final target = await FilePicker.saveFile(
      fileName: name,
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: mimeType,
      dialogTitle: 'Uložit soubor',
    );
    // Na webu se soubor stáhne a plugin vrací vždy `null`.
    return kIsWeb || target != null;
  }

  @override
  Future<String?> pickText(List<String> extensions) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (picked.isEmpty) return null;
    return utf8.decode(await picked.first.readAsBytes(), allowMalformed: true);
  }
}

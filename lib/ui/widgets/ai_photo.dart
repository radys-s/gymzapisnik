import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai/photo.dart';
import '../../state/app_state.dart';

/// Vybere fotku (`camera` = fotoaparát, jinak galerie). `null` = zrušeno.
typedef PhotoPicker = Future<Uint8List?> Function(bool camera);

Future<Uint8List?> pickPhoto(bool camera) async {
  final file = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: maxPhotoSide.toDouble(),
    maxHeight: maxPhotoSide.toDouble(),
    imageQuality: 80,
  );
  return file?.readAsBytes();
}

/// Upozornění před prvním použitím AI. Vrací `true`, když uživatel souhlasí.
Future<bool> confirmAiNotice(BuildContext context, AppState state) async {
  if (state.profile.aiNoticeAccepted) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Než použiješ AI'),
      content: const Text(
        'Fotka, seznam potravin nebo otázka trenérovi se odešle přes server '
        'aplikace do Cloudflare Workers AI. Server ji neukládá; výsledek si '
        'aplikace pamatuje jen v tomto zařízení.\n\n'
        'AI se může splést: výsledky si vždy zkontroluj. Rady a návrhy jsou '
        'jen inspirace, ne zdravotní, výživové ani trenérské doporučení '
        'odborníka.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Zrušit'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('Rozumím'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await state.acceptAiNotice();
  return true;
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai/photo.dart';
import '../../core/i18n.dart';
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
      title: Text(tr('Než použiješ AI', 'Before using AI')),
      content: Text(
        tr(
          'Fotka, seznam potravin nebo otázka trenérovi se odešle přes server '
              'aplikace do Cloudflare Workers AI. Server ji neukládá; výsledek si '
              'aplikace pamatuje jen v tomto zařízení.\n\n'
              'AI se může splést: výsledky si vždy zkontroluj. Rady a návrhy jsou '
              'jen inspirace, ne zdravotní, výživové ani trenérské doporučení '
              'odborníka.',
          'A photo, food list, or coach question is sent through the app server '
              'to Cloudflare Workers AI. The server does not store it; the result '
              'is kept only on this device.\n\n'
              'AI can be wrong: always double-check the results. Tips and '
              'suggestions are inspiration only, not medical, nutrition, or '
              'professional coaching advice.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(tr('Zrušit', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(tr('Rozumím', 'Got it')),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await state.acceptAiNotice();
  return true;
}

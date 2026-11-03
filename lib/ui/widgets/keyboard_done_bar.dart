import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Číselná klávesnice na iPhonu nemá klávesu, která by ji zasunula.
/// Nad otevřenou klávesnici proto přidá lištu s tlačítkem Hotovo
/// a klepnutí mimo pole klávesnici zavře.
class KeyboardDoneBar extends StatelessWidget {
  final Widget child;
  const KeyboardDoneBar({super.key, required this.child});

  static const height = 44.0;

  static void close() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final show = keyboard > 0 && defaultTargetPlatform == TargetPlatform.iOS;
    final content = GestureDetector(
      // Klepnutí, které nechytí žádný prvek, zavře klávesnici.
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: close,
      child: child,
    );
    final p = context.palette;
    // Strom má pořád stejný tvar: jinak by se při otevření klávesnice
    // celý obsah postavil znovu a pole by ztratilo fokus.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Obsah se zvedne i o lištu, ať pole nezakrývá.
        MediaQuery(
          data: show
              ? media.copyWith(
                  viewInsets: media.viewInsets.copyWith(
                    bottom: keyboard + height,
                  ),
                )
              : media,
          child: content,
        ),
        if (show)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            height: height,
            child: Material(
              color: p.elevated,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.separator)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: close,
                    child: const Text('Hotovo'),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

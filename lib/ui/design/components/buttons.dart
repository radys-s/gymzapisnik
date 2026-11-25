part of '../components.dart';

// Shared action buttons.

/// Primary screen action with a high contrast fill and clear direction icon.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  /// Section gradient instead of the default green one.
  final Tone? tone;

  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !busy;
    final fg = enabled ? p.onCta : p.tertiaryLabel;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(p.controlRadius),
    );
    // Vlastní uzel: jinak se popisek slije do rodiče přes celou obrazovku.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        child: Material(
          color: enabled ? p.cta : p.fill,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Bez vibrace: haptika jen u důležitých momentů (pauza, rekord).
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 52,
              child: Center(
                child: busy
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: p.secondaryLabel,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: fg, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: textFont,
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vedlejší akce stejné velikosti jako hlavní (šedé pozadí, barevný text).
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool destructive;

  const SecondaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = OutlinedButton.styleFrom(
      foregroundColor: destructive ? p.negative : p.label,
      backgroundColor: p.fill,
      minimumSize: const Size.fromHeight(52),
    );
    return PressScale(
      enabled: onPressed != null,
      child: icon == null
          ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 20),
              label: Text(label),
            ),
    );
  }
}

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
    final radius = BorderRadius.circular(p.controlRadius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final glow = tone?.color ?? p.cta;
    // Vlastní uzel: jinak se popisek slije do rodiče přes celou obrazovku.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        child: _CtaBody(
          radius: radius,
          glow: enabled ? glow : null,
          child: Ink(
            height: 52,
            decoration: ShapeDecoration(
              color: enabled ? null : p.fill,
              gradient: enabled ? (tone?.gradient ?? p.linear) : null,
              shape: shape,
            ),
            child: InkWell(
              customBorder: shape,
              // Bez vibrace: haptika jen u důležitých momentů (pauza, rekord).
              onTap: enabled ? onPressed : null,
              child: Center(
                child: busy
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: p.secondaryLabel,
                        ),
                      )
                    // Keep the action label and direction easy to scan.
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            Icon(
                              icon ?? Icons.arrow_forward,
                              color: fg,
                              size: 20,
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

/// Glow under an enabled main action and the sheen that passes over it.
class _CtaBody extends StatelessWidget {
  final BorderRadius radius;
  final Color? glow;
  final Widget child;
  const _CtaBody({
    required this.radius,
    required this.glow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: radius,
      boxShadow: glow == null ? null : context.palette.glow(glow!),
    ),
    child: Sheen(
      enabled: glow != null,
      borderRadius: radius,
      child: Material(type: MaterialType.transparency, child: child),
    ),
  );
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
      foregroundColor: destructive ? p.negative : p.accent,
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

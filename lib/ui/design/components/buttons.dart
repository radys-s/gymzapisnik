part of '../components.dart';

// Tlačítka.

/// Hlavní akce obrazovky. Aurora ve dne: přechod barev motivu.
/// Ve tmě a ve Studiu plná bílá / černá, na výrazné kartě kontrastní.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !busy;
    final fg = enabled ? p.onCta : p.tertiaryLabel;
    const shape = SkewBorder();
    // Vlastní uzel: jinak se popisek slije do rodiče přes celou obrazovku.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            height: 52,
            decoration: ShapeDecoration(
              color: enabled ? p.cta : p.fill,
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
                    // Popisek vlevo úzkým písmem, šipka vpravo.
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
                                  fontFamily: condensedFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 0.8,
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

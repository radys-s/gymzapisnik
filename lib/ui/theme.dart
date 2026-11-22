import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'design/tokens.dart';

export 'design/tokens.dart';

/// One dark visual system for the whole app, with a clear type hierarchy
/// and shared surfaces, controls, and colors.
ThemeData buildTheme() {
  const p = AppPalette.gym;
  const brightness = Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.gradient.first,
    onPrimaryContainer: p.onGradient,
    secondary: p.accent,
    onSecondary: p.onAccent,
    secondaryContainer: p.fill,
    onSecondaryContainer: p.label,
    tertiary: p.gradient.last,
    onTertiary: Colors.black,
    error: p.negative,
    onError: Colors.white,
    errorContainer: p.negative.withValues(alpha: 0.15),
    onErrorContainer: p.negative,
    surface: p.background,
    onSurface: p.label,
    onSurfaceVariant: p.secondaryLabel,
    surfaceDim: p.background,
    surfaceBright: p.elevated,
    surfaceContainerLowest: p.grouped,
    surfaceContainerLow: p.grouped,
    surfaceContainer: p.grouped,
    surfaceContainerHigh: p.elevated,
    surfaceContainerHighest: p.fill,
    outline: p.tertiaryLabel,
    outlineVariant: p.separator,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.gymGrey,
    onInverseSurface: Colors.black,
    inversePrimary: p.gradient.first,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    fontFamily: textFont,
    // Keep comfortable touch targets while allowing centered desktop layouts.
    visualDensity: VisualDensity.standard,
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );
  final t = base.textTheme;
  TextStyle s(TextStyle? from, double size, FontWeight w, [double ls = 0]) =>
      (from ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: p.label,
        height: 1.25,
      );
  // Use the same clear, rounded type hierarchy across every screen.
  TextStyle heading(TextStyle style) => style.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.12,
  );
  final text = t.copyWith(
    displaySmall: heading(s(t.displaySmall, 36, FontWeight.w800, -1.2)),
    headlineLarge: heading(s(t.headlineLarge, 30, FontWeight.w800, -1.0)),
    headlineMedium: heading(s(t.headlineMedium, 26, FontWeight.w700, -0.7)),
    headlineSmall: heading(s(t.headlineSmall, 22, FontWeight.w700, -0.5)),
    titleLarge: heading(s(t.titleLarge, 19, FontWeight.w700, -0.4)),
    titleMedium: s(t.titleMedium, 16, FontWeight.w600, -0.2),
    titleSmall: s(t.titleSmall, 14, FontWeight.w600, -0.1),
    bodyLarge: s(t.bodyLarge, 16, FontWeight.w400, -0.2),
    bodyMedium: s(t.bodyMedium, 14, FontWeight.w400, -0.1),
    bodySmall: s(
      t.bodySmall,
      13,
      FontWeight.w400,
      -0.05,
    ).copyWith(color: p.secondaryLabel),
    labelLarge: s(t.labelLarge, 16, FontWeight.w600, -0.2),
    labelMedium: s(
      t.labelMedium,
      12,
      FontWeight.w500,
    ).copyWith(color: p.secondaryLabel),
    labelSmall: s(
      t.labelSmall,
      11,
      FontWeight.w600,
      0.4,
    ).copyWith(color: p.tertiaryLabel),
  );

  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(p.controlRadius),
  );
  final OutlinedBorder buttonShape = control;
  const buttonSize = Size(minTap, 50);
  final buttonText = text.labelLarge;

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    dividerColor: p.separator,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.label,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleMedium,
      iconTheme: IconThemeData(color: p.label),
      actionsIconTheme: IconThemeData(color: p.label),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(
          size: 24,
          color: st.contains(WidgetState.selected)
              ? p.label
              : p.tertiaryLabel,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: st.contains(WidgetState.selected)
              ? p.label
              : p.tertiaryLabel,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.grouped,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: p.cardShape(),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.secondaryLabel,
      textColor: p.label,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
      minTileHeight: minTap + 4,
    ),
    dividerTheme: DividerThemeData(
      color: p.separator,
      thickness: 0.5,
      space: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: text.bodyLarge?.copyWith(color: p.tertiaryLabel),
      labelStyle: text.bodyLarge?.copyWith(color: p.secondaryLabel),
      floatingLabelStyle: text.bodySmall?.copyWith(color: p.accent),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall?.copyWith(color: p.negative),
      prefixIconColor: p.secondaryLabel,
      suffixIconColor: p.secondaryLabel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
        borderSide: BorderSide(color: p.negative),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
        borderSide: BorderSide(color: p.negative, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.3),
      selectionHandleColor: p.accent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: p.fill,
        disabledForegroundColor: p.tertiaryLabel,
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: control,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: p.fill,
        foregroundColor: p.label,
        disabledForegroundColor: p.tertiaryLabel,
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: buttonShape,
        side: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.fill,
        foregroundColor: p.label,
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: buttonShape,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize: const Size(minTap, minTap),
        textStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        shape: control,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.label,
        minimumSize: const Size(minTap, minTap),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(minTap, 40)),
        // Vybraný segment musí být poznat i bez tučného písma: výplň
        // a obrys v barvě akcentu.
        side: WidgetStateProperty.resolveWith(
          (st) => BorderSide(
            color: st.contains(WidgetState.selected) ? p.accent : p.fill,
            width: 2,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? p.accent.withValues(alpha: 0.22)
              : p.fill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (st) =>
              st.contains(WidgetState.selected) ? p.label : p.secondaryLabel,
        ),
        textStyle: WidgetStatePropertyAll(text.titleSmall),
        shape: WidgetStatePropertyAll(buttonShape),
      ),
      selectedIcon: const SizedBox.shrink(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.fill,
      selectedColor: p.accent.withValues(alpha: 0.18),
      disabledColor: p.fill,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
      ),
      labelStyle: text.titleSmall?.copyWith(color: p.label),
      secondaryLabelStyle: text.titleSmall?.copyWith(color: p.accent),
      checkmarkColor: p.accent,
      // Bez fajfky: vybraný chip se nerozšíří a řádek se nepřeskládá.
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? p.accent : p.fill,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? p.accent : null,
      ),
      checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      side: BorderSide(color: p.tertiaryLabel, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? p.accent : p.tertiaryLabel,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.fill,
      circularTrackColor: p.fill,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.fill,
      thumbColor: Colors.white,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
      shape: p.cardShape(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.grouped,
      modalBackgroundColor: p.grouped,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: p.tertiaryLabel,
      dragHandleSize: const Size(36, 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.sheet),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      // Světlý pruh: akce tmavou zelenou.
      actionTextColor: const Color(0xFFC2410C),
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      textStyle: text.bodyLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(p.controlRadius),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.elevated,
      dialBackgroundColor: p.fill,
      hourMinuteColor: p.fill,
      dayPeriodColor: p.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.elevated,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.elevated,
      headerForegroundColor: p.label,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );
}

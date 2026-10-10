import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'design/tokens.dart';

export 'design/tokens.dart';

/// Celý vzhled aplikace z jednoho místa: barvy ve stylu iOS, systémové
/// písmo (na iPhonu SF Pro) a zvolený barevný motiv. Žádná obrazovka
/// nemá spadnout do výchozího vzhledu Materialu.
ThemeData buildTheme(Brightness brightness, [Accent accent = Accent.lime]) {
  final p = AppPalette.of(brightness, accent);
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: dark ? Colors.black : Colors.white,
    primaryContainer: p.gradient.first,
    onPrimaryContainer: Colors.black,
    secondary: p.accent,
    onSecondary: dark ? Colors.black : Colors.white,
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
    inverseSurface: dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E),
    onInverseSurface: dark ? Colors.black : Colors.white,
    inversePrimary: p.gradient.first,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
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
  final text = t.copyWith(
    displaySmall: s(t.displaySmall, 40, FontWeight.w700, -0.8),
    headlineLarge: s(t.headlineLarge, 34, FontWeight.w700, -0.6),
    headlineMedium: s(t.headlineMedium, 28, FontWeight.w700, -0.4),
    headlineSmall: s(t.headlineSmall, 22, FontWeight.w700, -0.3),
    titleLarge: s(t.titleLarge, 20, FontWeight.w600, -0.2),
    titleMedium: s(t.titleMedium, 17, FontWeight.w600, -0.2),
    titleSmall: s(t.titleSmall, 15, FontWeight.w600),
    bodyLarge: s(t.bodyLarge, 17, FontWeight.w400, -0.2),
    bodyMedium: s(t.bodyMedium, 15, FontWeight.w400, -0.1),
    bodySmall: s(
      t.bodySmall,
      13,
      FontWeight.w400,
    ).copyWith(color: p.secondaryLabel),
    labelLarge: s(t.labelLarge, 17, FontWeight.w600, -0.2),
    labelMedium: s(
      t.labelMedium,
      13,
      FontWeight.w500,
    ).copyWith(color: p.secondaryLabel),
    labelSmall: s(
      t.labelSmall,
      12,
      FontWeight.w500,
    ).copyWith(color: p.secondaryLabel),
  );

  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.control),
  );
  const buttonSize = Size(minTap, 52);
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
      iconTheme: IconThemeData(color: p.accent),
      actionsIconTheme: IconThemeData(color: p.accent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.grouped,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 60,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(
          size: 26,
          color: st.contains(WidgetState.selected)
              ? p.accent
              : p.secondaryLabel,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: st.contains(WidgetState.selected)
              ? p.accent
              : p.secondaryLabel,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.grouped,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
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
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: p.negative),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
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
        shape: control,
        side: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.fill,
        foregroundColor: p.label,
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: control,
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
        foregroundColor: p.accent,
        minimumSize: const Size(minTap, minTap),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: const StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(minTap, 40)),
        side: WidgetStatePropertyAll(BorderSide(color: p.fill, width: 2)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? p.elevated : p.fill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (st) =>
              st.contains(WidgetState.selected) ? p.label : p.secondaryLabel,
        ),
        textStyle: WidgetStatePropertyAll(text.titleSmall),
        shape: WidgetStatePropertyAll(control),
      ),
      selectedIcon: const SizedBox.shrink(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.fill,
      selectedColor: p.accent.withValues(alpha: dark ? 0.25 : 0.15),
      disabledColor: p.fill,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: text.titleSmall?.copyWith(color: p.label),
      secondaryLabelStyle: text.titleSmall?.copyWith(color: p.accent),
      checkmarkColor: p.accent,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? p.positive : p.fill,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? p.accent : null,
      ),
      checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      side: BorderSide(color: p.tertiaryLabel, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.grouped,
      modalBackgroundColor: dark ? p.grouped : p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: p.tertiaryLabel,
      dragHandleSize: const Size(36, 5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      // Pruh má opačnou světlost než aplikace, tak i barva akce.
      actionTextColor: accent.solid(dark ? Brightness.light : Brightness.dark),
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      textStyle: text.bodyLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
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

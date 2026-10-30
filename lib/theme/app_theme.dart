import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DtColors extends ThemeExtension<DtColors> {
  const DtColors({
    required this.bgSubtle,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.primary,
    required this.primaryHover,
    required this.primary50,
    required this.onPrimary,
    required this.coral,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color bgSubtle;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color primary;
  final Color primaryHover;
  final Color primary50;
  final Color onPrimary;
  final Color coral;
  final Color success;
  final Color warning;
  final Color error;

  static const light = DtColors(
    bgSubtle: Color(0xFFF7F8FC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F3F9),
    border: Color(0xFFE5E8F2),
    text: Color(0xFF0B1533),
    textMuted: Color(0xFF5A6380),
    textSubtle: Color(0xFF6B7591),
    primary: Color(0xFF2D4BFF),
    primaryHover: Color(0xFF2238E0),
    primary50: Color(0xFFEEF1FF),
    onPrimary: Color(0xFFFFFFFF),
    coral: Color(0xFFFF5C39),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFE5484D),
  );

  static const dark = DtColors(
    bgSubtle: Color(0xFF0E1530),
    surface: Color(0xFF121A36),
    surfaceMuted: Color(0xFF1A2347),
    border: Color(0xFF2A3460),
    text: Color(0xFFF1F3F9),
    textMuted: Color(0xFFA9B0C6),
    textSubtle: Color(0xFF8A93AD),
    primary: Color(0xFF7C8CFF),
    primaryHover: Color(0xFF8B9BFF),
    primary50: Color(0x247C8CFF),
    onPrimary: Color(0xFF0B1533),
    coral: Color(0xFFFF7A5C),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFE5484D),
  );

  @override
  DtColors copyWith({
    Color? bgSubtle,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? textSubtle,
    Color? primary,
    Color? primaryHover,
    Color? primary50,
    Color? onPrimary,
    Color? coral,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return DtColors(
      bgSubtle: bgSubtle ?? this.bgSubtle,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primary50: primary50 ?? this.primary50,
      onPrimary: onPrimary ?? this.onPrimary,
      coral: coral ?? this.coral,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  DtColors lerp(ThemeExtension<DtColors>? other, double t) => other is DtColors ? other : this;
}

extension DtContext on BuildContext {
  DtColors get dt => Theme.of(this).extension<DtColors>() ?? DtColors.light;
}

ThemeData buildTheme({required bool isDark}) {
  final colors = isDark ? DtColors.dark : DtColors.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: colors.bgSubtle,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.coral,
      onSecondary: Colors.white,
      secondaryContainer: colors.primary50,
      onSecondaryContainer: colors.primary,
      error: colors.error,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
    ),
    dividerColor: colors.border,
    extensions: [colors],
  );
  final font = GoogleFonts.vazirmatn().fontFamily;
  final textTheme = base.textTheme.apply(
    fontFamily: font,
    bodyColor: colors.text,
    displayColor: colors.text,
  );
  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: colors.textSubtle),
      labelStyle: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primary50,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? colors.primary : colors.textMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? colors.primary : colors.textMuted,
        );
      }),
    ),
  );
}

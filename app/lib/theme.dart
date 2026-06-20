import 'package:flutter/material.dart';

const _primary = Color(0xFF1E4E5F);
const _secondary = Color(0xFF8FB9A8);
const _background = Color(0xFFF6F3EE);
const _text = Color(0xFF1F2933);
const _accent = Color(0xFFD98C7A);

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color backgroundPrimary;
  final Color backgroundCard;
  final Color backgroundGlass;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentMint;
  final Color accentPeach;
  final Color accentDeep;
  final Color borderSubtle;
  final Color shadowSoft;
  final Color glowLight;

  const AppThemeColors({
    required this.backgroundPrimary,
    required this.backgroundCard,
    required this.backgroundGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentMint,
    required this.accentPeach,
    required this.accentDeep,
    required this.borderSubtle,
    required this.shadowSoft,
    required this.glowLight,
  });

  @override
  AppThemeColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundCard,
    Color? backgroundGlass,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentMint,
    Color? accentPeach,
    Color? accentDeep,
    Color? borderSubtle,
    Color? shadowSoft,
    Color? glowLight,
  }) {
    return AppThemeColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundCard: backgroundCard ?? this.backgroundCard,
      backgroundGlass: backgroundGlass ?? this.backgroundGlass,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentMint: accentMint ?? this.accentMint,
      accentPeach: accentPeach ?? this.accentPeach,
      accentDeep: accentDeep ?? this.accentDeep,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      glowLight: glowLight ?? this.glowLight,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
      backgroundCard: Color.lerp(backgroundCard, other.backgroundCard, t)!,
      backgroundGlass: Color.lerp(backgroundGlass, other.backgroundGlass, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentMint: Color.lerp(accentMint, other.accentMint, t)!,
      accentPeach: Color.lerp(accentPeach, other.accentPeach, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
      glowLight: Color.lerp(glowLight, other.glowLight, t)!,
    );
  }
}

extension AppThemeTokens on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

const _appColors = AppThemeColors(
  backgroundPrimary: _background,
  backgroundCard: Color(0xFFFDFBF8),
  backgroundGlass: Color(0xDDFDFBF8),
  textPrimary: _text,
  textSecondary: Color(0xFF6D7478),
  textMuted: Color(0xFFB9BBB8),
  accentMint: _secondary,
  accentPeach: _accent,
  accentDeep: _primary,
  borderSubtle: Color(0x22B9BBB8),
  shadowSoft: Color(0x1F6D7478),
  glowLight: Color(0xCCFFFFFF),
);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: _primary,
    onPrimary: _appColors.backgroundCard,
    secondary: _secondary,
    onSecondary: _appColors.backgroundCard,
    tertiary: _accent,
    onTertiary: _appColors.backgroundCard,
    surface: _background,
    onSurface: _text,
    error: Color(0xFFB75E54),
    onError: _appColors.backgroundCard,
  ),
  scaffoldBackgroundColor: _background,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: _text, fontWeight: FontWeight.w300),
    bodyMedium: TextStyle(color: _text, fontWeight: FontWeight.w300),
    bodySmall: TextStyle(color: _text, fontWeight: FontWeight.w300),
    titleLarge: TextStyle(color: _text, fontWeight: FontWeight.w300),
    titleMedium: TextStyle(color: _text, fontWeight: FontWeight.w300),
    titleSmall: TextStyle(color: _text, fontWeight: FontWeight.w300),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _primary,
    foregroundColor: _background,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: _appColors.backgroundCard,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _accent,
    foregroundColor: _background,
  ),
  extensions: const <ThemeExtension<dynamic>>[_appColors],
  useMaterial3: true,
);

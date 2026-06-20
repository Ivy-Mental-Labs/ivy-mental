import 'package:flutter/material.dart';

const _primary = Color(0xFF1E4E5F);
const _secondary = Color(0xFF8FB9A8);
const _background = Color(0xFFF6F3EE);
const _text = Color(0xFF1F2933);
const _accent = Color(0xFFD98C7A);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: _primary,
    onPrimary: Colors.white,
    secondary: _secondary,
    onSecondary: Colors.white,
    tertiary: _accent,
    onTertiary: Colors.white,
    surface: _background,
    onSurface: _text,
    error: Colors.red,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: _background,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: _text),
    bodyMedium: TextStyle(color: _text),
    bodySmall: TextStyle(color: _text),
    titleLarge: TextStyle(color: _text),
    titleMedium: TextStyle(color: _text),
    titleSmall: TextStyle(color: _text),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _accent,
    foregroundColor: Colors.white,
  ),
  useMaterial3: true,
);

// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

const _seedColor = Color(0xFFE5732C);

final appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: _seedColor,
  brightness: Brightness.light,
  fontFamily: 'Roboto',
);

final appThemeDark = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: _seedColor,
  brightness: Brightness.dark,
  fontFamily: 'Roboto',
);

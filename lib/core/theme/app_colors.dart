import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF5E87F7);
  static const Color primaryLight = Color(0xFFECF2FF);
  static const Color primaryDark = Color(0xFF3D69D9);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF2C7BE5);

  // Semantic
  static const Color success = Color(0xFF2F9E44);
  static const Color warning = Color(0xFFE67700);
  static const Color error = Color(0xFFE03131);
  static const Color info = Color(0xFF1971C2);

  // Backgrounds
  static const Color background = Color(0xFFF3F6FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);

  // Dividers / Borders
  static const Color divider = Color(0xFFDEE2E6);
  static const Color shadow = Color(0x1A000000);

  // Subject color palette for timetable grid
  static const List<Color> subjectColors = [
    Color(0xFF4DABF7),
    Color(0xFF69DB7C),
    Color(0xFFFF8787),
    Color(0xFFDA77F2),
    Color(0xFFFFE066),
    Color(0xFF63E6BE),
    Color(0xFFFF922B),
    Color(0xFF74C0FC),
    Color(0xFFA9E34B),
    Color(0xFFE599F7),
  ];

  static const List<Color> subjectColorsDark = [
    Color(0xFF1971C2),
    Color(0xFF2F9E44),
    Color(0xFFE03131),
    Color(0xFF9C36B5),
    Color(0xFFE67700),
    Color(0xFF0CA678),
    Color(0xFFD9480F),
    Color(0xFF1C7ED6),
    Color(0xFF5C940D),
    Color(0xFF862E9C),
  ];

  // Holiday color
  static const Color holidayBackground = Color(0xFFFFF5F5);
  static const Color holidayText = Color(0xFFE03131);
  static const Color holidayBorder = Color(0xFFFFB3B3);

  // Break / free slot
  static const Color breakBackground = Color(0xFFF1F3F5);
  static const Color breakText = Color(0xFF868E96);

  // Lab session
  static const Color labBackground = Color(0xFFE3FAFC);
  static const Color labText = Color(0xFF0C8599);

  // Admin tag
  static const Color adminBadgeBackground = Color(0xFFFFF3BF);
  static const Color adminBadgeText = Color(0xFFE67700);

  // Status colors
  static const Color activeGreen = Color(0xFF2F9E44);
  static const Color inactiveGray = Color(0xFF868E96);
}

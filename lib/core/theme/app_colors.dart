import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF6E6E73);

  // FIXED: Changed to monochrome sleek greys instead of colorful tags
  static const Color priorityLow = Color(0xFF3A3A3C);
  static const Color priorityMedium = Color(0xFF48484A);
  static const Color priorityHigh = Color(0xFF636366);

  static const Color categoryWork = Color(0xFF3A3A3C);
  static const Color categoryPersonal = Color(0xFF48484A);
  static const Color categoryOther = Color(0xFF636366);
}
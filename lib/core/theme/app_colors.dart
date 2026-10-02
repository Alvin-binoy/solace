import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Primary ──
  static const Color primary = Color(0xFF9E9E9E);        // PLACEHOLDER
  static const Color primaryLight = Color(0xFFCFCFCF);
  static const Color primaryDark = Color(0xFF707070);

  // ── Accent ──
  static const Color accent = Color(0xFFBDBDBD);          // PLACEHOLDER

  // ── Surfaces ──
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // ── Semantic ──
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ── Task Priority Colors ──
  static const Color priorityLow = Color(0xFF81C784);
  static const Color priorityMedium = Color(0xFFFFD54F);
  static const Color priorityHigh = Color(0xFFFF8A65);
  static const Color priorityUrgent = Color(0xFFEF5350);

  // ── Task Category Colors ──
  static const Color categoryWork = Color(0xFF5C6BC0);
  static const Color categoryPersonal = Color(0xFF26C6DA);
  static const Color categoryHealth = Color(0xFF66BB6A);
  static const Color categoryStudy = Color(0xFFAB47BC);
  static const Color categoryOther = Color(0xFF78909C);
}
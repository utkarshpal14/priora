import 'package:flutter/material.dart';

/// Priora Design System Colors (Document 07 - Option 1: Charcoal / Ivory / Muted Emerald)
class AppColors {
  // Primary Brand Colors
  static const Color background = Color(0xFFF8F6F2); // Warm Ivory
  static const Color primary = Color(0xFF1D1D1D); // Deep Charcoal
  static const Color accent = Color(0xFF2D6A4F); // Muted Emerald
  static const Color accentLight = Color(0xFFD8F3DC); // Soft Emerald Tint

  // Surface & Card Colors
  static const Color surface = Color(0xFFFFFFFF); // Pure White Card Surface
  static const Color surfaceSubtle = Color(0xFFF0EDE6); // Slightly darker Ivory
  static const Color border = Color(0xFFE5E0D8); // Subtle Warm Border
  static const Color divider = Color(0xFFECE7DF);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Priority Colors
  static const Color priorityCritical = Color(0xFFDC2626);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityMedium = Color(0xFFD97706);
  static const Color priorityLow = Color(0xFF2D6A4F);

  // Status & Feedback Colors
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);
}

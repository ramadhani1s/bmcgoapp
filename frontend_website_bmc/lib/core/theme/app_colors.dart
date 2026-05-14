import 'package:flutter/material.dart';

/// Shared color palette for web dashboards (admin & mentor)
class AppColors {
  // Backgrounds
  static const Color pageBg = Color(0xFFF1F4FA);
  static const Color sidebarBg = Color(0xFFF8FAFD);
  static const Color surface = Colors.white;

  // Borders
  static const Color border = Color(0xFFDDE4F0);
  static const Color softBorder = Color(0xFFE9EFF8);

  // Primary / Brand
  static const Color primary = Color(0xFF2B57E4);
  static const Color primaryVariant = Color(0xFF2756F0);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Menu / active gradient (slightly lighter)
  static const LinearGradient menuGradient = LinearGradient(
    colors: [Color(0xFF2A58F2), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Accents
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color blueLightBg = Color(0xFFDBEAFE);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  // Status colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFECFDF3);
  static const Color warning = Color(0xFFF97316);
  static const Color warningBg = Color(0xFFFFF7ED);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);

  // Misc
  static const Color notification = Color(0xFFFF4057);
}

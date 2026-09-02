import 'package:flutter/material.dart';

/// ZhiroFactor color palette — modern, professional, with rich status colors.
class AppColors {
  AppColors._();

  // ─── Brand Gradient ─────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00BFA5);

  // ─── Dark Theme Surface Colors ──────────────────────────────────────
  static const Color scaffoldDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1A1D27);
  static const Color cardDark = Color(0xFF222639);
  static const Color cardDarkAlt = Color(0xFF1E2235);
  static const Color dividerDark = Color(0xFF2A2E3F);

  // ─── Text Colors ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFFB0B3C5);
  static const Color textMuted = Color(0xFF6B6F82);

  // ─── Invoice Status Colors ──────────────────────────────────────────
  static const Color statusSettled = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusDeposit = Color(0xFFFF9800);
  static const Color statusCancelled = Color(0xFFEF5350);

  // ─── Sidebar ────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF141722);
  static const Color sidebarActiveItem = Color(0xFF1A73E8);
  static const Color sidebarHover = Color(0xFF1E2235);

  // ─── Data Table ─────────────────────────────────────────────────────
  static const Color tableRowEven = Color(0xFF1A1D27);
  static const Color tableRowOdd = Color(0xFF1E2235);
  static const Color tableHeader = Color(0xFF222639);

  // ─── Misc ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFCA28);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ─── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF141722), Color(0xFF0F1117)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient kpiCardGradient1 = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient kpiCardGradient2 = LinearGradient(
    colors: [Color(0xFF00BFA5), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient kpiCardGradient3 = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFFFCA28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient kpiCardGradient4 = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the appropriate status color for an invoice status string.
  static Color statusColor(String status) {
    switch (status) {
      case 'تسویه شده':
        return statusSettled;
      case 'در انتظار پرداخت':
        return statusPending;
      case 'بیعانه':
        return statusDeposit;
      case 'لغو شده':
        return statusCancelled;
      default:
        return textMuted;
    }
  }
}

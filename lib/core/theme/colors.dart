import 'package:flutter/material.dart';

/// Linear.com-inspired color palette
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bgBase = Color(0xFF0F0F0F);
  static const Color bgSurface = Color(0xFF141414);
  static const Color bgElevated = Color(0xFF1A1A1A);
  static const Color bgOverlay = Color(0xFF222222);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF222222);
  static const Color borderDefault = Color(0xFF2A2A2A);
  static const Color borderEmphasis = Color(0xFF383838);
  static const Color borderFocus = Color(0xFF7C3AED);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF7F7F7);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFF444444);
  static const Color textInverse = Color(0xFF0F0F0F);

  // ── Accent / Primary ──────────────────────────────────────────────────────
  static const Color accent = Color(0xFF7C3AED);       // purple
  static const Color accentHover = Color(0xFF8B5CF6);
  static const Color accentMuted = Color(0xFF2D1B69);
  static const Color accentText = Color(0xFFA78BFA);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF26A67A);
  static const Color successMuted = Color(0xFF0D2E22);
  static const Color warning = Color(0xFFF2AC57);
  static const Color warningMuted = Color(0xFF2D200A);
  static const Color error = Color(0xFFE5484D);
  static const Color errorMuted = Color(0xFF2D0E0F);

  // ── Tag badge colors ──────────────────────────────────────────────────────
  static const Color tagShopping = Color(0xFF26A67A);     // green
  static const Color tagShoppingMuted = Color(0xFF0D2E22);
  static const Color tagLink = Color(0xFF7C3AED);          // purple
  static const Color tagLinkMuted = Color(0xFF2D1B69);
  static const Color tagEvent = Color(0xFFF2AC57);         // amber
  static const Color tagEventMuted = Color(0xFF2D200A);
  static const Color tagNote = Color(0xFFD9B86C);          // warm sand
  static const Color tagNoteMuted = Color(0xFF2A2418);
  static const Color tagQr = Color(0xFF38BDF8);            // sky cyan
  static const Color tagQrMuted = Color(0xFF0B2436);
  static const Color tagTodo = Color(0xFFE5484D);          // red
  static const Color tagTodoMuted = Color(0xFF2D0E0F);

  // ── Section time-of-day colors ────────────────────────────────────────────
  static const Color sectionMorning = Color(0xFFF2AC57);   // warm amber
  static const Color sectionAfternoon = Color(0xFF7C3AED); // purple
  static const Color sectionAnytime = Color(0xFF6B6B6B);   // grey
  static const Color sectionEvent = Color(0xFF26A67A);     // green
}

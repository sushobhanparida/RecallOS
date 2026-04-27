import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayLg => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
      );

  static TextStyle get displayMd => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
      );

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle get headingLg => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.4,
      );

  static TextStyle get headingMd => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
      );

  static TextStyle get headingSm => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLg => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMd => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySm => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLg => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get labelMd => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get labelSm => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.3,
      );

  // ── Mono ──────────────────────────────────────────────────────────────────
  static TextStyle get monoMd => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get monoSm => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );
}

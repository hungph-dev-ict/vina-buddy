import 'package:flutter/material.dart';

/// Centralized semantic color tokens for Smart Inbox AI.
class AppColors {
  // Brand & Primary
  static const Color primaryLight = Color(0xFF3B5CE6);
  static const Color primaryDark = Color(0xFF6366F1);
  static const Color primaryContainerLight = Color(0xFFEEF2FF);
  static const Color primaryContainerDark = Color(0xFF1E1B4B);
  static const Color onPrimaryContainerLight = Color(0xFF1E3A8A);
  static const Color onPrimaryContainerDark = Color(0xFFC7D2FE);

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceContainerLight = Color(0xFFF1F5F9);
  static const Color surfaceContainerDark = Color(0xFF1F2937);

  // Outlines & Dividers
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineDark = Color(0xFF374151);
  static const Color outlineVariantLight = Color(0xFFCBD5E1);
  static const Color outlineVariantDark = Color(0xFF4B5563);

  // Typography
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF6B7280);

  // Semantic Status Colors
  static const Color successLight = Color(0xFF059669);
  static const Color successDark = Color(0xFF10B981);
  static const Color successContainerLight = Color(0xFFECFDF5);
  static const Color successContainerDark = Color(0xFF064E3B);
  static const Color onSuccessContainerLight = Color(0xFF065F46);
  static const Color onSuccessContainerDark = Color(0xFFA7F3D0);

  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningContainerLight = Color(0xFFFFFBEB);
  static const Color warningContainerDark = Color(0xFF451A03);
  static const Color onWarningContainerLight = Color(0xFF92400E);
  static const Color onWarningContainerDark = Color(0xFFFDE68A);

  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color errorContainerLight = Color(0xFFFEF2F2);
  static const Color errorContainerDark = Color(0xFF450A0A);
  static const Color onErrorContainerLight = Color(0xFF991B1B);
  static const Color onErrorContainerDark = Color(0xFFFECACA);

  // AI & Intent Accent
  static const Color aiAccentLight = Color(0xFF7C3AED);
  static const Color aiAccentDark = Color(0xFFA78BFA);
  static const Color aiAccentContainerLight = Color(0xFFF5F3FF);
  static const Color aiAccentContainerDark = Color(0xFF2E1065);
  static const Color onAiAccentContainerLight = Color(0xFF5B21B6);
  static const Color onAiAccentContainerDark = Color(0xFFDDD6FE);

  /// Helper to get text primary color according to context brightness.
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  /// Helper to get text secondary color according to context brightness.
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }

  /// Helper to get muted text color according to context brightness.
  static Color textMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textMutedDark
        : textMutedLight;
  }
}

import 'package:flutter/material.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';

enum AppBadgeVariant {
  neutral,
  addLabel,
  removeLabel,
  aiConfidence,
  aiProvider,
  condition,
}

/// Reusable badge / pill widget for labels, AI confidence, and rule tokens.
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;
  final double? confidence; // 0.0 to 1.0 if variant == aiConfidence

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.neutral,
    this.confidence,
  });

  factory AppBadge.addLabel(String label) {
    return AppBadge(
      label: label,
      icon: Icons.add_rounded,
      variant: AppBadgeVariant.addLabel,
    );
  }

  factory AppBadge.removeLabel(String label) {
    return AppBadge(
      label: label,
      icon: Icons.remove_rounded,
      variant: AppBadgeVariant.removeLabel,
    );
  }

  factory AppBadge.confidence(double score) {
    final percent = (score * 100).toInt();
    return AppBadge(
      label: '$percent%',
      icon: score >= 0.70
          ? Icons.check_circle_outline
          : Icons.warning_amber_rounded,
      variant: AppBadgeVariant.aiConfidence,
      confidence: score,
    );
  }

  factory AppBadge.provider(String name) {
    return AppBadge(
      label: name,
      icon: Icons.auto_awesome_rounded,
      variant: AppBadgeVariant.aiProvider,
    );
  }

  factory AppBadge.condition(String field, String op, String val) {
    return AppBadge(
      label: '$field $op "$val"',
      icon: Icons.filter_alt_outlined,
      variant: AppBadgeVariant.condition,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (variant) {
      case AppBadgeVariant.addLabel:
        bgColor = isDark
            ? AppColors.successContainerDark
            : AppColors.successContainerLight;
        textColor = isDark
            ? AppColors.onSuccessContainerDark
            : AppColors.onSuccessContainerLight;
        borderColor = isDark
            ? AppColors.successDark.withValues(alpha: 0.3)
            : AppColors.successLight.withValues(alpha: 0.3);
        break;
      case AppBadgeVariant.removeLabel:
        bgColor = isDark
            ? AppColors.errorContainerDark
            : AppColors.errorContainerLight;
        textColor = isDark
            ? AppColors.onErrorContainerDark
            : AppColors.onErrorContainerLight;
        borderColor = isDark
            ? AppColors.errorDark.withValues(alpha: 0.3)
            : AppColors.errorLight.withValues(alpha: 0.3);
        break;
      case AppBadgeVariant.aiConfidence:
        final isHigh = (confidence ?? 1.0) >= 0.70;
        if (isHigh) {
          bgColor = isDark
              ? AppColors.successContainerDark
              : AppColors.successContainerLight;
          textColor = isDark
              ? AppColors.onSuccessContainerDark
              : AppColors.onSuccessContainerLight;
          borderColor = isDark
              ? AppColors.successDark.withValues(alpha: 0.3)
              : AppColors.successLight.withValues(alpha: 0.3);
        } else {
          bgColor = isDark
              ? AppColors.warningContainerDark
              : AppColors.warningContainerLight;
          textColor = isDark
              ? AppColors.onWarningContainerDark
              : AppColors.onWarningContainerLight;
          borderColor = isDark
              ? AppColors.warningDark.withValues(alpha: 0.3)
              : AppColors.warningLight.withValues(alpha: 0.3);
        }
        break;
      case AppBadgeVariant.aiProvider:
        bgColor = isDark
            ? AppColors.aiAccentContainerDark
            : AppColors.aiAccentContainerLight;
        textColor = isDark
            ? AppColors.onAiAccentContainerDark
            : AppColors.onAiAccentContainerLight;
        borderColor = isDark
            ? AppColors.aiAccentDark.withValues(alpha: 0.3)
            : AppColors.aiAccentLight.withValues(alpha: 0.3);
        break;
      case AppBadgeVariant.condition:
        bgColor = isDark
            ? AppColors.primaryContainerDark
            : AppColors.primaryContainerLight;
        textColor = isDark
            ? AppColors.onPrimaryContainerDark
            : AppColors.onPrimaryContainerLight;
        borderColor = isDark
            ? AppColors.primaryDark.withValues(alpha: 0.3)
            : AppColors.primaryLight.withValues(alpha: 0.3);
        break;
      case AppBadgeVariant.neutral:
        bgColor = isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight;
        textColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        borderColor = isDark ? AppColors.outlineDark : AppColors.outlineLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

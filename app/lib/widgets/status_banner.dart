import 'package:flutter/material.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';

enum StatusBannerType { info, warning, error, success }

/// Semantic banner for alerts, uncertainty warnings, and sync failure recovery.
class StatusBanner extends StatelessWidget {
  final String message;
  final StatusBannerType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry margin;

  const StatusBanner({
    super.key,
    required this.message,
    this.type = StatusBannerType.info,
    this.actionLabel,
    this.onAction,
    this.margin = EdgeInsets.zero,
  });

  factory StatusBanner.warning({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return StatusBanner(
      message: message,
      type: StatusBannerType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      margin: margin,
    );
  }

  factory StatusBanner.error({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return StatusBanner(
      message: message,
      type: StatusBannerType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData iconData;

    switch (type) {
      case StatusBannerType.info:
        bgColor = isDark
            ? AppColors.primaryContainerDark
            : AppColors.primaryContainerLight;
        borderColor = isDark
            ? AppColors.primaryDark.withValues(alpha: 0.3)
            : AppColors.primaryLight.withValues(alpha: 0.3);
        textColor = isDark
            ? AppColors.onPrimaryContainerDark
            : AppColors.onPrimaryContainerLight;
        iconData = Icons.info_outline_rounded;
        break;
      case StatusBannerType.warning:
        bgColor = isDark
            ? AppColors.warningContainerDark
            : AppColors.warningContainerLight;
        borderColor = isDark
            ? AppColors.warningDark.withValues(alpha: 0.4)
            : AppColors.warningLight.withValues(alpha: 0.4);
        textColor = isDark
            ? AppColors.onWarningContainerDark
            : AppColors.onWarningContainerLight;
        iconData = Icons.warning_amber_rounded;
        break;
      case StatusBannerType.error:
        bgColor = isDark
            ? AppColors.errorContainerDark
            : AppColors.errorContainerLight;
        borderColor = isDark
            ? AppColors.errorDark.withValues(alpha: 0.4)
            : AppColors.errorLight.withValues(alpha: 0.4);
        textColor = isDark
            ? AppColors.onErrorContainerDark
            : AppColors.onErrorContainerLight;
        iconData = Icons.error_outline_rounded;
        break;
      case StatusBannerType.success:
        bgColor = isDark
            ? AppColors.successContainerDark
            : AppColors.successContainerLight;
        borderColor = isDark
            ? AppColors.successDark.withValues(alpha: 0.4)
            : AppColors.successLight.withValues(alpha: 0.4);
        textColor = isDark
            ? AppColors.onSuccessContainerDark
            : AppColors.onSuccessContainerLight;
        iconData = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, size: 18, color: textColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

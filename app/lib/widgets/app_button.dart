import 'package:flutter/material.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive, text }

/// Production-ready button with unified heights, loading states, and typography.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
  });

  factory AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.primary,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  factory AppButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.outlined,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  factory AppButton.destructive({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isFullWidth = true,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.destructive,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingColor(context, isDark),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: _getTextColor(context, isDark),
          ),
        ),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight,
            foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.primaryContainerDark
                : AppColors.primaryContainerLight,
            foregroundColor: isDark
                ? AppColors.onPrimaryContainerDark
                : AppColors.onPrimaryContainerLight,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            side: BorderSide(
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.destructive:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            side: BorderSide(
              color: isDark ? AppColors.errorDark : AppColors.errorLight,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        );
        break;
    }

    return button;
  }

  Color _getLoadingColor(BuildContext context, bool isDark) {
    if (variant == AppButtonVariant.primary) {
      return isDark ? const Color(0xFF0B0F19) : Colors.white;
    }
    if (variant == AppButtonVariant.destructive) {
      return isDark ? AppColors.errorDark : AppColors.errorLight;
    }
    return isDark ? AppColors.primaryDark : AppColors.primaryLight;
  }

  Color _getTextColor(BuildContext context, bool isDark) {
    if (onPressed == null && !isLoading) {
      return isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return isDark ? const Color(0xFF0B0F19) : Colors.white;
      case AppButtonVariant.secondary:
        return isDark
            ? AppColors.onPrimaryContainerDark
            : AppColors.onPrimaryContainerLight;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      case AppButtonVariant.destructive:
        return isDark ? AppColors.errorDark : AppColors.errorLight;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_badge.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';

/// Structured Rule Card component for rules screen.
class RuleCard extends StatelessWidget {
  final RuleModel rule;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onPreview;
  final VoidCallback? onDelete;
  final String previewLabel;
  final String deleteTooltip;

  const RuleCard({
    super.key,
    required this.rule,
    this.onToggle,
    this.onPreview,
    this.onDelete,
    this.previewLabel = 'Preview',
    this.deleteTooltip = 'Delete Rule',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: rule.enabled
          ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
          : (isDark ? const Color(0xFF161F2E) : const Color(0xFFF8FAFC)),
      borderColor: rule.enabled
          ? (isDark ? AppColors.outlineDark : AppColors.outlineLight)
          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Status Switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rule.enabled
                            ? (isDark
                                  ? AppColors.successDark
                                  : AppColors.successLight)
                            : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rule.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: rule.enabled
                              ? (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight)
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.enabled,
                onChanged: onToggle,
                activeTrackColor: isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Natural language quote block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              borderRadius: AppRadius.roundedSm,
              border: Border(
                left: BorderSide(
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              '"${rule.naturalLanguage}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Pills (Add Label / Remove Label)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: rule.actions.map((a) {
              if (a.type == 'add_label') {
                return AppBadge.addLabel(a.label);
              } else {
                return AppBadge.removeLabel(a.label);
              }
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bottom Bar: Preview & Delete actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onPreview != null)
                TextButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: Text(
                    previewLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: deleteTooltip,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: isDark ? AppColors.errorDark : AppColors.errorLight,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

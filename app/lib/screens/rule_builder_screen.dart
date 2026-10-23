import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/preview_dialog.dart';
import 'package:smart_inbox_ai/screens/widgets/admin_report_dialog.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_badge.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';

class RuleBuilderScreen extends ConsumerStatefulWidget {
  const RuleBuilderScreen({super.key});

  @override
  ConsumerState<RuleBuilderScreen> createState() => _RuleBuilderScreenState();
}

class _RuleBuilderScreenState extends ConsumerState<RuleBuilderScreen> {
  final TextEditingController _controller = TextEditingController();
  List<RuleModel> _generatedRules = [];

  Future<void> _submitRule() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    final rule = await ref.read(rulesProvider.notifier).createRule(text);
    if (rule != null && mounted) {
      setState(() {
        _generatedRules = [rule, ...rule.subRules];
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rulesState = ref.watch(rulesProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presets = [
      l10n?.presetNewsletters ?? 'Move newsletters to Newsletters label',
      l10n?.presetShopping ?? 'Label emails from amazon.com as Shopping',
      l10n?.presetSecurity ?? 'Label security alerts as Security',
      l10n?.presetInvoices ?? 'Label receipts and invoices as Finance',
    ];

    final isUnsupported = rulesState.errorMessage != null &&
        (rulesState.errorMessage!.toLowerCase().contains('không thể hỗ trợ') ||
            rulesState.errorMessage!.toLowerCase().contains('admin') ||
            rulesState.errorMessage!.toLowerCase().contains('unsupported'));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ruleBuilderTitle ?? 'AI Rule Builder'),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.primaryContainerLight,
              borderColor: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.25)
                  : AppColors.primaryLight.withValues(alpha: 0.2),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n?.describeRuleHint ??
                          'Describe your inbox rule in plain English or Vietnamese:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Text Input
            TextField(
              controller: _controller,
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: l10n?.ruleInputPlaceholder ??
                    'e.g. Label all emails from substack.com as Newsletters',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Presets Header & Chips
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: presets.map((preset) {
                return InkWell(
                  onTap: () {
                    _controller.text = preset;
                  },
                  borderRadius: AppRadius.roundedSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLight,
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(
                        color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.south_west_rounded,
                          size: 11,
                          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          preset,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            AppButton.primary(
              label: rulesState.isLoading
                  ? (l10n?.analyzingButton ?? 'Analyzing Intent...')
                  : (l10n?.analyzeButton ?? 'Convert to Structured Rule'),
              isLoading: rulesState.isLoading,
              icon: const Icon(Icons.auto_awesome, size: 18),
              onPressed: _submitRule,
            ),

            if (rulesState.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              StatusBanner.error(
                message: rulesState.errorMessage!,
              ),
              if (isUnsupported) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton.outlined(
                  label: l10n?.reportToAdmin ?? 'Report to Admin',
                  icon: const Icon(Icons.report_problem_outlined, size: 18),
                  onPressed: () async {
                    final sent = await AdminReportDialog.show(
                      context,
                      _controller.text.trim(),
                    );
                    if (sent == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.reportSuccess ??
                                'Report submitted to admin successfully!',
                          ),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],

            if (_generatedRules.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isDark ? AppColors.successDark : AppColors.successLight,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _generatedRules.length > 1
                        ? (l10n?.multipleRulesGenerated(_generatedRules.length) ??
                            'Separated into ${_generatedRules.length} independent rules')
                        : (l10n?.generatedRulePreview ?? 'Generated Rule'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              ..._generatedRules.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final rule = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_generatedRules.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            l10n?.ruleIndex(idx) ?? 'Rule #$idx',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],

                      // Uncertainty alert if low confidence
                      if (rule.isUncertain)
                        StatusBanner.warning(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          message: l10n?.uncertaintyWarning((rule.llmConfidence * 100).toInt()) ??
                              'Uncertain match (confidence: ${(rule.llmConfidence * 100).toInt()}%). '
                              'Verify conditions before applying.',
                        ),

                      AppCard(
                        hasShadow: true,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and badges
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    rule.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                AppBadge.confidence(rule.llmConfidence),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppBadge.provider(rule.llmProvider),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                              child: Divider(height: 1),
                            ),

                            // Conditions
                            Text(
                              l10n?.conditions ?? 'Conditions:',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: rule.conditions.map((c) {
                                return AppBadge.condition(c.field, c.operator, c.value);
                              }).toList(),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Target Actions
                            Text(
                              l10n?.targetActions ?? 'Proposed Actions:',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
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

                            const SizedBox(height: AppSpacing.lg),

                            // Preview Action CTA
                            AppButton.primary(
                              label: l10n?.previewAndApply ?? 'Preview Affected Emails',
                              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                              onPressed: () => PreviewDialog.show(context, rule),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/preview_dialog.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/empty_state_view.dart';
import 'package:smart_inbox_ai/widgets/rule_card.dart';

class RulesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToBuilder;

  const RulesScreen({super.key, this.onNavigateToBuilder});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rulesProvider.notifier).fetchRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rulesState = ref.watch(rulesProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.myRulesTitle ?? 'My Rules'),
        actions: [
          IconButton(
            icon: rulesState.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: l10n?.refreshRules ?? 'Refresh Rules',
            onPressed: () => ref.read(rulesProvider.notifier).fetchRules(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: rulesState.isLoading && rulesState.rules.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            )
          : rulesState.rules.isEmpty
              ? EmptyStateView(
                  icon: Icons.rule_folder_outlined,
                  title: l10n?.noRulesConfigured ?? 'No rules configured yet.',
                  subtitle: l10n?.noRulesSubtitle ?? 'Create your first rule using plain English.',
                  buttonLabel: l10n?.createRuleButton ?? 'Create Rule',
                  onButtonPressed: widget.onNavigateToBuilder,
                )
              : Column(
                  children: [
                    // Status bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${rulesState.rules.where((r) => r.enabled).length} of ${rulesState.rules.length} active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: rulesState.rules.length,
                        itemBuilder: (context, index) {
                          final rule = rulesState.rules[index];
                          return RuleCard(
                            rule: rule,
                            previewLabel: l10n?.previewRule ?? 'Preview',
                            deleteTooltip: l10n?.deleteRule ?? 'Delete Rule',
                            onToggle: (val) {
                              ref.read(rulesProvider.notifier).toggleRule(rule.id, val);
                            },
                            onPreview: () => PreviewDialog.show(context, rule),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n?.deleteRuleConfirmTitle ?? 'Delete Rule'),
                                  content: Text(
                                    l10n?.deleteRuleConfirmContent ??
                                        'Are you sure you want to delete this rule?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n?.cancel ?? 'Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        l10n?.delete ?? 'Delete',
                                        style: TextStyle(
                                          color: isDark ? AppColors.errorDark : AppColors.errorLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(rulesProvider.notifier).deleteRule(rule.id);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

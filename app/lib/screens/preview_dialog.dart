import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/models/preview_model.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_badge.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/empty_state_view.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';

class PreviewDialog extends ConsumerStatefulWidget {
  final RuleModel rule;

  const PreviewDialog({super.key, required this.rule});

  static Future<void> show(BuildContext context, RuleModel rule) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PreviewDialog(rule: rule),
    );
  }

  @override
  ConsumerState<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends ConsumerState<PreviewDialog> {
  bool _loading = true;
  String? _error;
  PreviewModel? _preview;
  final Set<String> _selectedEmailIds = {};
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.previewRule(widget.rule.id);
      setState(() {
        _preview = res;
        _selectedEmailIds.addAll(res.matches.map((m) => m.emailId));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleSelectAll() {
    if (_preview == null) return;
    setState(() {
      if (_selectedEmailIds.length == _preview!.matches.length) {
        _selectedEmailIds.clear();
      } else {
        _selectedEmailIds.clear();
        _selectedEmailIds.addAll(_preview!.matches.map((m) => m.emailId));
      }
    });
  }

  Future<void> _applyApprovedActions() async {
    if (_selectedEmailIds.isEmpty) return;

    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.confirmApplyTitle ?? 'Confirm Label Application'),
        content: Text(
          l10n?.confirmApplyContent(_selectedEmailIds.length) ??
              'Apply labels to ${_selectedEmailIds.length} approved email(s)?\n\n'
                  'No emails will be deleted or sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n?.approveAndApply(_selectedEmailIds.length) ??
                  'Approve & Apply',
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _applying = true);

    try {
      final api = ref.read(apiServiceProvider);
      final summary = await api.applyApprovedActions(
        ruleId: widget.rule.id,
        approvedEmailIds: _selectedEmailIds.toList(),
      );

      // Refresh inbox feed
      ref.read(emailsProvider.notifier).syncEmails();

      if (mounted) {
        Navigator.pop(context); // Close preview sheet
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n?.applySuccessTitle ?? 'Actions Applied'),
            content: Text(
              l10n?.applySuccessContent(summary.succeeded) ??
                  'Successfully applied labels to ${summary.succeeded} email(s).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n?.close ?? 'Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _applying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalMatches = _preview?.totalMatches ?? 0;
    final isAllSelected =
        _selectedEmailIds.length == totalMatches && totalMatches > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.modal(context),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.outlineDark
                    : AppColors.outlineVariantLight,
                borderRadius: AppRadius.roundedPill,
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n?.previewTitle ?? "Preview"}: ${widget.rule.name}',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedEmailIds.length} of $totalMatches approved',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalMatches > 0)
                  TextButton(
                    onPressed: _toggleSelectAll,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      isAllSelected
                          ? (l10n?.deselectAll ?? 'Deselect All')
                          : (l10n?.selectAll ?? 'Select All'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Body
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: StatusBanner.error(
                        message: 'Error: $_error',
                        actionLabel: 'Retry',
                        onAction: _loadPreview,
                      ),
                    ),
                  )
                : _preview == null || _preview!.matches.isEmpty
                ? EmptyStateView(
                    icon: Icons.filter_list_off_rounded,
                    title:
                        l10n?.noEmailsMatched ?? 'No emails matched this rule.',
                    subtitle: 'No emails in your synced inbox meet all rule conditions.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: _preview!.matches.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.outlineDark
                          : AppColors.outlineLight,
                    ),
                    itemBuilder: (context, index) {
                      final match = _preview!.matches[index];
                      final isSelected = _selectedEmailIds.contains(
                        match.emailId,
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedEmailIds.add(match.emailId);
                            } else {
                              _selectedEmailIds.remove(match.emailId);
                            }
                          });
                        },
                        title: Text(
                          match.subject,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              match.fromEmail,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: match.proposedActions.map((a) {
                                return AppBadge.addLabel(a.label);
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.outlineDark
                      : AppColors.outlineLight,
                  width: 1,
                ),
              ),
              boxShadow: AppShadows.subtle(context),
            ),
            child: SafeArea(
              child: AppButton.primary(
                label: _applying
                    ? (l10n?.applyingChanges ?? 'Applying changes...')
                    : (l10n?.approveAndApply(_selectedEmailIds.length) ??
                          'Apply Actions (${_selectedEmailIds.length})'),
                isLoading: _applying,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                onPressed: (_selectedEmailIds.isEmpty || _applying)
                    ? null
                    : _applyApprovedActions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

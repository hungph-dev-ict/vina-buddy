import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/widgets/language_selector.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/email_card.dart';
import 'package:smart_inbox_ai/widgets/empty_state_view.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final emailsState = ref.read(emailsProvider);
      if (emailsState.emails.isEmpty) {
        ref.read(emailsProvider.notifier).syncEmails();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emailsState = ref.watch(emailsProvider);
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.inboxFeedTitle ?? 'Inbox Feed'),
        actions: [
          IconButton(
            icon: emailsState.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: l10n?.syncEmails ?? 'Sync Emails',
            onPressed: emailsState.isLoading
                ? null
                : () => ref.read(emailsProvider.notifier).syncEmails(),
          ),
          const LanguageSelectorAction(isCompact: true),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    Icon(Icons.account_circle, size: 18, color: isDark ? AppColors.primaryDark : AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.userConnected(authState.email ?? "Connected") ??
                            'User: ${authState.email ?? "Connected"}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: isDark ? AppColors.errorDark : AppColors.errorLight),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.disconnect ?? 'Disconnect',
                      style: TextStyle(color: isDark ? AppColors.errorDark : AppColors.errorLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(emailsProvider.notifier).syncEmails(),
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        child: Column(
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
                    Icons.mark_email_unread_outlined,
                    size: 15,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n?.emailsSynced(emailsState.emails.length) ??
                        '${emailsState.emails.length} emails synced',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (emailsState.lastSyncedAt != null)
                    Text(
                      l10n?.updatedTime(DateFormat.jm().format(emailsState.lastSyncedAt!)) ??
                          'Updated: ${DateFormat.jm().format(emailsState.lastSyncedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                ],
              ),
            ),

            if (emailsState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: StatusBanner.error(
                  message: emailsState.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: () => ref.read(emailsProvider.notifier).syncEmails(),
                ),
              ),

            Expanded(
              child: emailsState.isLoading && emailsState.emails.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                    )
                  : emailsState.emails.isEmpty
                      ? EmptyStateView(
                          icon: Icons.all_inbox_rounded,
                          title: l10n?.noEmailsFound ?? 'No emails synced yet.',
                          subtitle: l10n?.pullToRefreshHint ??
                              'Tap sync or pull to fetch your recent inbox messages.',
                          buttonLabel: l10n?.syncEmails ?? 'Sync Emails',
                          onButtonPressed: () =>
                              ref.read(emailsProvider.notifier).syncEmails(),
                        )
                      : ListView.separated(
                          itemCount: emailsState.emails.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                          ),
                          itemBuilder: (context, index) {
                            final email = emailsState.emails[index];
                            return EmailCard(email: email);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

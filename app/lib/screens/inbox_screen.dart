import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/widgets/language_selector.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/email_card.dart';
import 'package:smart_inbox_ai/widgets/empty_state_view.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';

enum InboxFilter { all, unread, labeled }

class InboxScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToBuilder;

  const InboxScreen({super.key, this.onNavigateToBuilder});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxFilter _activeFilter = InboxFilter.all;

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

  List<EmailItem> _filterEmails(List<EmailItem> allEmails) {
    switch (_activeFilter) {
      case InboxFilter.unread:
        return allEmails.where((e) => e.labels.contains('UNREAD')).toList();
      case InboxFilter.labeled:
        return allEmails
            .where((e) => e.labels.any((l) => l != 'INBOX' && l != 'UNREAD'))
            .toList();
      case InboxFilter.all:
        return allEmails;
    }
  }

  void _cyclePlatform() {
    final current = ref.read(platformOverrideProvider);
    final effective = current ?? Theme.of(context).platform;
    final next = effective == TargetPlatform.iOS
        ? TargetPlatform.android
        : TargetPlatform.iOS;
    HapticFeedback.mediumImpact();
    ref.read(platformOverrideProvider.notifier).setPlatform(next);
  }

  void _showIosAccountSheet(
    BuildContext context,
    AuthState authState,
    AppLocalizations? l10n,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          l10n?.appName ?? 'Vina Buddy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        message: Text(
          l10n?.userConnected(authState.email ?? 'Connected') ??
              'User: ${authState.email ?? "Connected"}',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(l10n?.disconnect ?? 'Disconnect'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailsState = ref.watch(emailsProvider);
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final platformOverride = ref.watch(platformOverrideProvider);
    final effectivePlatform = platformOverride ?? Theme.of(context).platform;
    final isIos = effectivePlatform == TargetPlatform.iOS;

    final filteredEmails = _filterEmails(emailsState.emails);
    final unreadCount = emailsState.emails
        .where((e) => e.labels.contains('UNREAD'))
        .length;
    final labeledCount = emailsState.emails
        .where((e) => e.labels.any((l) => l != 'INBOX' && l != 'UNREAD'))
        .length;

    if (isIos) {
      return _buildIosHomeScreen(
        context: context,
        isDark: isDark,
        emailsState: emailsState,
        authState: authState,
        filteredEmails: filteredEmails,
        unreadCount: unreadCount,
        labeledCount: labeledCount,
        l10n: l10n,
      );
    }

    return _buildAndroidHomeScreen(
      context: context,
      isDark: isDark,
      emailsState: emailsState,
      authState: authState,
      filteredEmails: filteredEmails,
      unreadCount: unreadCount,
      labeledCount: labeledCount,
      l10n: l10n,
    );
  }

  // ---------------------------------------------------------------------------
  // iOS Apple HIG Home Screen
  // ---------------------------------------------------------------------------
  Widget _buildIosHomeScreen({
    required BuildContext context,
    required bool isDark,
    required dynamic emailsState,
    required AuthState authState,
    required List<EmailItem> filteredEmails,
    required int unreadCount,
    required int labeledCount,
    required AppLocalizations? l10n,
  }) {
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFFFFFFF);
    final separatorColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Cupertino Large Title Navigation Bar
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              l10n?.inboxFeedTitle ?? 'Inbox Feed',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xD9121212)
                : const Color(0xD9F9F9F9),
            border: Border(
              bottom: BorderSide(color: separatorColor, width: 0.5),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Platform Switcher
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(44, 44),
                  onPressed: _cyclePlatform,
                  child: const Icon(
                    CupertinoIcons.device_phone_portrait,
                    size: 20,
                    color: Color(0xFF007AFF),
                  ),
                ),
                // Language Switcher
                const LanguageSelectorAction(isCompact: true),
                // Sync Button
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(44, 44),
                  onPressed: emailsState.isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          ref.read(emailsProvider.notifier).syncEmails();
                        },
                  child: emailsState.isLoading
                      ? const CupertinoActivityIndicator(radius: 9)
                      : const Icon(
                          CupertinoIcons.arrow_clockwise,
                          size: 20,
                          color: Color(0xFF007AFF),
                        ),
                ),
                // User Profile / Logout
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(44, 44),
                  onPressed: () =>
                      _showIosAccountSheet(context, authState, l10n),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 22,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),

          // Native iOS Pull-to-refresh
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await ref.read(emailsProvider.notifier).syncEmails();
            },
          ),

          // Status & Segmented Filter Control
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sync status subtitle
                  Row(
                    children: [
                      Text(
                        l10n?.emailsSynced(emailsState.emails.length) ??
                            '${emailsState.emails.length} emails synced',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6C6C70),
                        ),
                      ),
                      const Spacer(),
                      if (emailsState.lastSyncedAt != null)
                        Text(
                          l10n?.updatedTime(
                                DateFormat.jm().format(
                                  emailsState.lastSyncedAt!,
                                ),
                              ) ??
                              'Updated: ${DateFormat.jm().format(emailsState.lastSyncedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF636366)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Cupertino Segmented Control (Thumb Zone)
                  SizedBox(
                    height: 36,
                    child: CupertinoSlidingSegmentedControl<InboxFilter>(
                      groupValue: _activeFilter,
                      backgroundColor: isDark
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFE5E5EA),
                      thumbColor: isDark
                          ? const Color(0xFF636366)
                          : const Color(0xFFFFFFFF),
                      onValueChanged: (filter) {
                        if (filter != null) {
                          HapticFeedback.selectionClick();
                          setState(() => _activeFilter = filter);
                        }
                      },
                      children: {
                        InboxFilter.all: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${l10n?.filterAll ?? 'All'} (${emailsState.emails.length})',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        InboxFilter.unread: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${l10n?.filterUnread ?? 'Unread'} ($unreadCount)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        InboxFilter.labeled: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${l10n?.filterLabeled ?? 'With Labels'} ($labeledCount)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      },
                    ),
                  ),

                  if (emailsState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    StatusBanner.error(
                      message: emailsState.errorMessage!,
                      actionLabel: 'Retry',
                      onAction: () =>
                          ref.read(emailsProvider.notifier).syncEmails(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Email Inset Grouped List
          if (emailsState.isLoading && emailsState.emails.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            )
          else if (emailsState.emails.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: CupertinoIcons.tray,
                title: l10n?.noEmailsFound ?? 'No emails synced yet.',
                subtitle:
                    l10n?.pullToRefreshHint ??
                    'Tap sync or pull to fetch your recent inbox messages.',
                buttonLabel: l10n?.syncEmails ?? 'Sync Emails',
                onButtonPressed: () =>
                    ref.read(emailsProvider.notifier).syncEmails(),
              ),
            )
          else if (filteredEmails.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: CupertinoIcons.line_horizontal_3_decrease_circle,
                title: 'No emails in this filter',
                subtitle: 'Try switching filters to view other messages.',
                buttonLabel: l10n?.filterAll ?? 'Show All',
                onButtonPressed: () {
                  setState(() => _activeFilter = InboxFilter.all);
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: separatorColor, width: 0.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredEmails.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 48,
                      color: separatorColor,
                    ),
                    itemBuilder: (context, index) {
                      final email = filteredEmails[index];
                      return EmailCard(email: email, isIosOverride: true);
                    },
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Android Material 3 Home Screen
  // ---------------------------------------------------------------------------
  Widget _buildAndroidHomeScreen({
    required BuildContext context,
    required bool isDark,
    required dynamic emailsState,
    required AuthState authState,
    required List<EmailItem> filteredEmails,
    required int unreadCount,
    required int labeledCount,
    required AppLocalizations? l10n,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.inboxFeedTitle ?? 'Inbox Feed',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // Platform Switcher
          IconButton(
            icon: const Icon(Icons.phone_iphone_rounded),
            tooltip: 'Preview Apple HIG Mode',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: _cyclePlatform,
          ),
          // Refresh / Sync
          IconButton(
            icon: emailsState.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: l10n?.syncEmails ?? 'Sync Emails',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: emailsState.isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    ref.read(emailsProvider.notifier).syncEmails();
                  },
          ),
          const LanguageSelectorAction(isCompact: true),
          // Account Popup Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                    Icon(
                      Icons.account_circle,
                      size: 20,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.userConnected(authState.email ?? "Connected") ??
                            'User: ${authState.email ?? "Connected"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
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
                    Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.errorDark
                          : AppColors.errorLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.disconnect ?? 'Disconnect',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.errorDark
                            : AppColors.errorLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),

      // Material 3 Floating Action Button in thumb zone
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.onNavigateToBuilder?.call();
        },
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        elevation: 3,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(
          l10n?.newRuleAction ?? 'New Rule',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await ref.read(emailsProvider.notifier).syncEmails();
        },
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        child: Column(
          children: [
            // M3 Status ribbon
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.outlineDark
                        : AppColors.outlineLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n?.emailsSynced(emailsState.emails.length) ??
                        '${emailsState.emails.length} emails synced',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (emailsState.lastSyncedAt != null)
                    Text(
                      l10n?.updatedTime(
                            DateFormat.jm().format(emailsState.lastSyncedAt!),
                          ) ??
                          'Updated: ${DateFormat.jm().format(emailsState.lastSyncedAt!)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                ],
              ),
            ),

            // Material 3 Filter Chips Row (Thumb zone)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _activeFilter == InboxFilter.all,
                      selectedColor: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.25)
                          : AppColors.primaryLight.withValues(alpha: 0.15),
                      checkmarkColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      label: Text(
                        '${l10n?.filterAll ?? 'All'} (${emailsState.emails.length})',
                        style: TextStyle(
                          color: _activeFilter == InboxFilter.all
                              ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          fontWeight: _activeFilter == InboxFilter.all
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onSelected: (selected) {
                        HapticFeedback.lightImpact();
                        setState(() => _activeFilter = InboxFilter.all);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _activeFilter == InboxFilter.unread,
                      selectedColor: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.25)
                          : AppColors.primaryLight.withValues(alpha: 0.15),
                      checkmarkColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      avatar: unreadCount > 0
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      label: Text(
                        '${l10n?.filterUnread ?? 'Unread'} ($unreadCount)',
                        style: TextStyle(
                          color: _activeFilter == InboxFilter.unread
                              ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          fontWeight: _activeFilter == InboxFilter.unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onSelected: (selected) {
                        HapticFeedback.lightImpact();
                        setState(() => _activeFilter = InboxFilter.unread);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _activeFilter == InboxFilter.labeled,
                      selectedColor: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.25)
                          : AppColors.primaryLight.withValues(alpha: 0.15),
                      checkmarkColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      label: Text(
                        '${l10n?.filterLabeled ?? 'With Labels'} ($labeledCount)',
                        style: TextStyle(
                          color: _activeFilter == InboxFilter.labeled
                              ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          fontWeight: _activeFilter == InboxFilter.labeled
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onSelected: (selected) {
                        HapticFeedback.lightImpact();
                        setState(() => _activeFilter = InboxFilter.labeled);
                      },
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
                  onAction: () =>
                      ref.read(emailsProvider.notifier).syncEmails(),
                ),
              ),

            // Email List
            Expanded(
              child: emailsState.isLoading && emailsState.emails.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    )
                  : emailsState.emails.isEmpty
                  ? EmptyStateView(
                      icon: Icons.all_inbox_rounded,
                      title: l10n?.noEmailsFound ?? 'No emails synced yet.',
                      subtitle: l10n?.pullToRefreshHint ?? 'Tap sync or pull to fetch your recent inbox messages.',
                      buttonLabel: l10n?.syncEmails ?? 'Sync Emails',
                      onButtonPressed: () =>
                          ref.read(emailsProvider.notifier).syncEmails(),
                    )
                  : filteredEmails.isEmpty
                  ? EmptyStateView(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No emails in this filter',
                      subtitle: 'Try switching filters to view other messages.',
                      buttonLabel: l10n?.filterAll ?? 'Show All',
                      onButtonPressed: () {
                        setState(() => _activeFilter = InboxFilter.all);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredEmails.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineLight,
                      ),
                      itemBuilder: (context, index) {
                        final email = filteredEmails[index];
                        return EmailCard(email: email, isIosOverride: false);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

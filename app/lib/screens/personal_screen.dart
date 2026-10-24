import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/main.dart';
import 'package:smart_inbox_ai/screens/auth_screen.dart';
import 'package:smart_inbox_ai/screens/widgets/naming_dialog.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_badge.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final platformOverride = ref.watch(platformOverrideProvider);
    final effectivePlatform = platformOverride ?? Theme.of(context).platform;
    final isIos = effectivePlatform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.personalTitle ?? 'Settings & Profile'),
        centerTitle: isIos,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        children: [
          // 1. Account Profile Card
          _buildAccountCard(context, ref, authState, isDark, l10n),
          const SizedBox(height: AppSpacing.xl),

          // 2. Virtual Office Assistant Naming
          _buildSectionHeader(
            context,
            title: 'Văn phòng ảo vnverse',
            icon: Icons.business_center_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAssistantNamingCard(context, ref, isDark),
          const SizedBox(height: AppSpacing.xl),

          // 3. Appearance Section
          _buildSectionHeader(
            context,
            title: l10n?.appearanceSection ?? 'Appearance',
            icon: isIos ? CupertinoIcons.paintbrush : Icons.palette_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildThemeSelector(context, ref, currentThemeMode, isDark, l10n),
          const SizedBox(height: AppSpacing.xl),

          // 4. Language & Region Section
          _buildSectionHeader(
            context,
            title: l10n?.languageSection ?? 'Language',
            icon: isIos ? CupertinoIcons.globe : Icons.translate_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageSelector(context, ref, currentLocale, isDark, l10n),
          // 5. Backend Server Connection (for real device testing & ngrok)
          _buildSectionHeader(
            context,
            title: 'Máy chủ Backend (ngrok / LAN IP)',
            icon: Icons.dns_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildServerUrlCard(context, ref, isDark),
          const SizedBox(height: AppSpacing.xl),

          // 6. Privacy & Security Assurance
          _buildPrivacyCard(context, isDark, l10n),
          const SizedBox(height: AppSpacing.xl),

          // 7. Tribute to Minister of vnverse
          _buildMinisterCard(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // 8. App Version Footer
          Center(
            child: Text(
              'vnverse v1.0.0 (Virtual Office PoC)',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final email = authState.email ?? 'user@gmail.com';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
    final errorColor = isDark ? AppColors.errorDark : AppColors.errorLight;

    return AppCard(
      hasShadow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark
                    ? AppColors.primaryContainerDark
                    : AppColors.primaryContainerLight,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.accountSection ?? 'Connected Account',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    AppBadge(
                      label: email.contains('mock') || email.contains('sandbox')
                          ? (l10n?.statusSandbox ?? 'Dev / Sandbox Mode')
                          : (l10n?.statusConnected ?? 'Google OAuth Connected'),
                      variant: AppBadgeVariant.aiConfidence,
                      confidence: 1.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: BorderSide(
                  color: errorColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n?.disconnectAccount ?? 'Log Out / Disconnect'),
              onPressed: () => _confirmLogout(context, ref, l10n, errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    Color errorColor,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.disconnectConfirmTitle ?? 'Disconnect Account?'),
        content: Text(
          l10n?.disconnectConfirmMsg ??
              'You will be returned to the onboarding screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.disconnect ?? 'Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(authProvider.notifier).logout();
      appNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentThemeMode,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment<ThemeMode>(
            value: ThemeMode.system,
            label: Text(l10n?.themeSystem ?? 'System'),
            icon: const Icon(Icons.brightness_auto_rounded, size: 18),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            label: Text(l10n?.themeLight ?? 'Light'),
            icon: const Icon(Icons.light_mode_rounded, size: 18),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            label: Text(l10n?.themeDark ?? 'Dark'),
            icon: const Icon(Icons.dark_mode_rounded, size: 18),
          ),
        ],
        selected: {currentThemeMode},
        onSelectionChanged: (newSelection) {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
        },
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment<String>(
            value: 'en',
            label: Text('English (EN)'),
            icon: Icon(Icons.language_rounded, size: 18),
          ),
          ButtonSegment<String>(
            value: 'vi',
            label: Text('Tiếng Việt (VI)'),
            icon: Icon(Icons.flag_rounded, size: 18),
          ),
        ],
        selected: {currentLocale.languageCode},
        onSelectionChanged: (newSelection) {
          HapticFeedback.selectionClick();
          ref
              .read(localeProvider.notifier)
              .setLocale(Locale(newSelection.first));
        },
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(
    BuildContext context,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return AppCard(
      backgroundColor: isDark
          ? AppColors.surfaceContainerDark.withValues(alpha: 0.5)
          : AppColors.primaryContainerLight.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 24,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.privacySection ?? 'Privacy & Security',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n?.privacySubtitle ?? 'Zero permanent storage • Read & label only • Explicit approval',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantNamingCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final coordName = ref.watch(coordinatorNameProvider);

    return AppCard(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
          ),
          title: const Text(
            'Tên Trợ lý Giám đốc',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            coordName,
            style: TextStyle(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.edit_outlined, size: 20),
          onTap: () async {
            final newName = await NamingDialog.show(
              context,
              title: 'Đổi tên Trợ lý Giám đốc',
              currentName: coordName,
              subtitle: 'Đặt tên riêng cho người bạn đồng hành AI đắc lực trong văn phòng ảo của sếp.',
            );
            if (newName != null && newName.trim().isNotEmpty) {
              await ref.read(coordinatorNameProvider.notifier).setName(newName);
            }
          },
        ),
      ),
    );
  }

  Widget _buildServerUrlCard(BuildContext context, WidgetRef ref, bool isDark) {
    final serverUrl = ref.watch(serverUrlProvider);

    return AppCard(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dns_rounded,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 20,
            ),
          ),
          title: Text(
            serverUrl,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          subtitle: Text(
            'Nhấn để đổi địa chỉ máy chủ (ngrok, LAN IP, v.v.)',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: () => _showServerConfigDialog(context, ref, serverUrl),
        ),
      ),
    );
  }

  void _showServerConfigDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUrl,
  ) {
    final controller = TextEditingController(text: currentUrl);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình máy chủ Backend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ ngrok HTTPS hoặc IP LAN của máy tính chạy backend:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://xxxx.ngrok-free.app',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(serverUrlProvider.notifier).setBaseUrl(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildMinisterCard(BuildContext context, bool isDark) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎩', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Bộ trưởng vnverse',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ứng dụng được sáng lập và phát triển bởi Bộ trưởng vnverse. '
              'Mọi yêu cầu hoặc nghiệp vụ mà các nhân viên trên thị trường chưa xử lý được sẽ được gửi trực tiếp lên bàn Bộ trưởng để xem xét chiêu mộ nhân tài từ nước ngoài.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

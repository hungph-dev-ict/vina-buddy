import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/widgets/language_selector.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          LanguageSelectorAction(isCompact: true),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Hero Icon
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF3730A3), const Color(0xFF1E1B4B)]
                            : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppColors.primaryDark.withValues(alpha: 0.3)
                            : AppColors.primaryLight.withValues(alpha: 0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                              .withValues(alpha: 0.12),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        size: 44,
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  l10n?.appName ?? 'Smart Inbox AI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    l10n?.authTagline ??
                        'Personal Gmail triage powered by natural-language AI rules with safe, user-approved label actions.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.45,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Security guarantees card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  hasShadow: true,
                  child: Column(
                    children: [
                      _SecurityRow(
                        icon: Icons.shield_outlined,
                        title: l10n?.zeroPermanentStorageTitle ?? 'Zero Permanent Storage',
                        subtitle: l10n?.zeroPermanentStorageSubtitle ?? 'Full email bodies are never stored or logged.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Divider(height: 1),
                      ),
                      _SecurityRow(
                        icon: Icons.label_important_outline_rounded,
                        title: l10n?.labelsOnlyTitle ?? 'Labels Only',
                        subtitle: l10n?.labelsOnlySubtitle ?? 'Never deletes, archives, or sends emails.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Divider(height: 1),
                      ),
                      _SecurityRow(
                        icon: Icons.verified_user_outlined,
                        title: l10n?.explicitApprovalTitle ?? 'Explicit Approval',
                        subtitle: l10n?.explicitApprovalSubtitle ?? 'You preview and approve every action.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Error Message if present
                if (authState.errorMessage != null) ...[
                  StatusBanner.error(
                    message: authState.errorMessage!,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  ),
                ],

                // Connect Button
                AppButton.primary(
                  label: l10n?.connectGmail ?? 'Connect Gmail (Google OAuth)',
                  isLoading: authState.isLoading,
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  onPressed: () => ref.read(authProvider.notifier).loginGoogle(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Dev Mode Sandbox Button
                AppButton.outlined(
                  label: l10n?.continueDevMode ?? 'Continue in Dev/Sandbox Mode',
                  isLoading: authState.isLoading,
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  onPressed: () => ref.read(authProvider.notifier).loginGoogle(
                        authCode: 'mock_sandbox_tester_code',
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : AppColors.primaryContainerLight,
            borderRadius: AppRadius.roundedSm,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

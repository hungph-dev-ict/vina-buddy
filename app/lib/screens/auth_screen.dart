import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/main.dart';
import 'package:smart_inbox_ai/screens/main_navigation_screen.dart';
import 'package:smart_inbox_ai/screens/widgets/language_selector.dart';
import 'package:smart_inbox_ai/services/api_service.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded),
            tooltip: 'Server URL',
            onPressed: () => _showServerConfigDialog(context, ref, serverUrl),
          ),
          const LanguageSelectorAction(isCompact: true),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
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
                            : [
                                const Color(0xFFEEF2FF),
                                const Color(0xFFE0E7FF),
                              ],
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
                          color:
                              (isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight)
                                  .withValues(alpha: 0.12),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.business_center_rounded,
                        size: 44,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  l10n?.appName ?? 'vnverse',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Văn phòng ảo AI độc đáo dành riêng cho bạn. Đăng nhập để trở thành Giám đốc và chiêu mộ những nhân viên AI tài năng nhất!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
                        icon: Icons.workspace_premium_rounded,
                        title: 'Chủ quyền Giám đốc',
                        subtitle: 'Bạn là Giám đốc, nắm toàn quyền điều hành công ty và đặt tên cho các nhân viên AI.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Divider(height: 1),
                      ),
                      _SecurityRow(
                        icon: Icons.shield_outlined,
                        title: 'Bảo mật & Riêng tư',
                        subtitle: 'Xác thực qua tài khoản Google an toàn, không lưu trữ thông tin nhạy cảm.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Divider(height: 1),
                      ),
                      _SecurityRow(
                        icon: Icons.people_outline_rounded,
                        title: 'Chiêu mộ nhân tài',
                        subtitle: 'Khám phá Chợ tuyển dụng để bổ sung nhân sự chuyên trách bất cứ khi nào bạn muốn.',
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
                  isLoading: authState.isGoogleLoading,
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  onPressed: () => _handleConnectGoogleOAuth(context, ref),
                ),
                const SizedBox(height: AppSpacing.md),

                // Dev Mode Sandbox Button
                AppButton.outlined(
                  label:
                      l10n?.continueDevMode ?? 'Continue in Dev/Sandbox Mode',
                  isLoading: authState.isDevLoading,
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  onPressed: () =>
                      ref.read(authProvider.notifier).loginDevMode(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Offline Sandbox Button if connection error occurred
                if (authState.errorMessage != null) ...[
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(authProvider.notifier).enterOfflineSandbox(),
                    icon: const Icon(Icons.offline_bolt_outlined, size: 18),
                    label: const Text(
                      'Bypass Login: Open Offline Sandbox Mode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],

                // Server Status Indicator / Selector
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: InkWell(
                    onTap: () =>
                        _showServerConfigDialog(context, ref, serverUrl),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerDark
                            : AppColors.surfaceContainerLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.outlineDark.withValues(alpha: 0.5)
                              : AppColors.outlineLight.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dns_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              serverUrl,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showServerConfigDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUrl,
  ) async {
    final controller = TextEditingController(text: currentUrl);
    String? testResult;
    bool isTesting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Backend Server URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'On real phones, http://10.0.2.2 will not work. Enter your Mac Wi-Fi IP (e.g. http://192.168.1.xxx:8000) or ngrok HTTPS URL:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Server URL',
                    hintText: 'http://192.168.1.xxx:8000',
                  ),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: testResult!.startsWith('Connected')
                          ? AppColors.successLight
                          : AppColors.errorLight,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isTesting
                    ? null
                    : () async {
                        setDialogState(() {
                          isTesting = true;
                          testResult = 'Testing connection...';
                        });
                        try {
                          final tempApi = ApiService(
                            baseUrl: controller.text.trim(),
                          );
                          final health = await tempApi.checkHealth();
                          setDialogState(() {
                            isTesting = false;
                            testResult = 'Connected! Status: ${health.status}';
                          });
                        } catch (e) {
                          setDialogState(() {
                            isTesting = false;
                            testResult = 'Failed: $e';
                          });
                        }
                      },
                child: isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(serverUrlProvider.notifier)
                      .setBaseUrl(controller.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleConnectGoogleOAuth(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final serverUrl = ref.read(serverUrlProvider);
    final apiService = ref.read(apiServiceProvider);
    final authNotifier = ref.read(authProvider.notifier);

    authNotifier.setGoogleLoading(true);

    try {
      final host = serverUrl
          .replaceAll(RegExp(r'^https?://'), '')
          .replaceAll(RegExp(r'/+$'), '');

      final authUrlRes = await apiService.getGoogleAuthUrl(serverHost: host);

      if (authUrlRes['configured'] != true) {
        authNotifier.setGoogleLoading(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Google OAuth chưa được cấu hình trên server. Vui lòng kiểm tra backend .env',
              ),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
        return;
      }

      final authUrl = authUrlRes['auth_url'] as String;
      final state = authUrlRes['state'] as String;

      final uri = Uri.parse(authUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(
          'Không thể khởi chạy trình duyệt. Vui lòng mở thủ công link sau:\n$authUrl',
        );
      }

      if (context.mounted) {
        await _showWaitingGoogleLoginDialog(context, ref, state: state);
      }
    } catch (e) {
      authNotifier.setGoogleLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi Google SSO: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _showWaitingGoogleLoginDialog(
    BuildContext context,
    WidgetRef ref, {
    required String state,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Timer? pollTimer;
    int pollAttempts = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Start polling every 1.2 seconds for snappy response
        pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (
          timer,
        ) async {
          pollAttempts++;
          if (pollAttempts > 120) {
            timer.cancel();
            authNotifier.setGoogleLoading(false);
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
            return;
          }

          try {
            final res = await apiService.pollGoogleAuth(state: state);
            if (res['status'] == 'completed') {
              timer.cancel();
              final email = res['email'] as String? ?? 'user@gmail.com';
              final token = res['session_token'] as String? ?? '';

              if (ctx.mounted &&
                  Navigator.of(ctx, rootNavigator: true).canPop()) {
                Navigator.of(ctx, rootNavigator: true).pop();
              }

              authNotifier.setAuthenticated(email: email, sessionToken: token);

              appNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Đã kết nối Gmail thật thành công: $email'),
                    backgroundColor: AppColors.successLight,
                  ),
                );
              }
            }
          } catch (_) {
            // Ignore transient network errors while polling
          }
        });

        return AlertDialog(
          title: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              const Text(
                'Đang chờ đăng nhập...',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vui lòng nhập tài khoản Gmail, mật khẩu và đồng ý cấp quyền trên trang Google vừa mở.',
                style: TextStyle(fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                'Ứng dụng Vina Buddy sẽ tự động hoàn tất đăng nhập ngay khi bạn xác nhận xong trên trình duyệt!',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  final codeController = TextEditingController();
                  showDialog(
                    context: ctx,
                    builder: (manualCtx) => AlertDialog(
                      title: const Text('Nhập mã xác thực thủ công'),
                      content: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Mã xác thực (code)',
                          hintText: '4/0Axxxx...',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(manualCtx),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () {
                            final code = codeController.text.trim();
                            Navigator.pop(manualCtx);
                            if (code.isNotEmpty) {
                              pollTimer?.cancel();
                              Navigator.pop(ctx);
                              authNotifier.loginGoogle(authCode: code);
                            }
                          },
                          child: const Text('Xác nhận'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.paste_rounded, size: 16),
                label: const Text('Nhập mã OAuth thủ công'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                pollTimer?.cancel();
                authNotifier.setGoogleLoading(false);
                Navigator.pop(ctx);
              },
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );

    pollTimer?.cancel();
    authNotifier.setGoogleLoading(false);
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
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.primaryContainerLight,
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
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
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

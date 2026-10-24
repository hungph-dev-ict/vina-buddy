import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';

class RecruitmentMarketScreen extends ConsumerWidget {
  const RecruitmentMarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogService = ref.watch(agentCatalogServiceProvider);
    final agents = catalogService.getAllAgents();
    final recruitedAgents = ref.watch(recruitedAgentsProvider);
    final availableAgents = agents
        .where((agent) => !recruitedAgents.any((a) => a.agentId == agent.id))
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chợ tuyển dụng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        children: [
          // Market Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🎪', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(
                      'Sàn Nhân Tài vnverse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Chiêu mộ các nhân viên AI chuyên trách về phục vụ công ty của Giám đốc. Lương 0 đồng, không đòi bảo hiểm, trung thành tuyệt đối!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE0E7FF),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (availableAgents.isEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Đã chiêu mộ toàn bộ nhân sự!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tất cả nhân tài trên Chợ tuyển dụng hiện đã gia nhập công ty của Giám đốc. Hãy vào mục Bạn bè để giao việc, hoặc chờ Bộ trưởng vnverse chiêu mộ thêm nhân tài mới!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...availableAgents.map((agent) {
              return _buildAgentMarketCard(
                context,
                ref,
                agent: agent,
                isRecruited: false,
                isDark: isDark,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAgentMarketCard(
    BuildContext context,
    WidgetRef ref, {
    required AgentDefinition agent,
    required bool isRecruited,
    required bool isDark,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      agent.avatarSymbol,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agent.defaultName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: agent.isPlaceholder
                                  ? AppColors.amber.withValues(alpha: 0.15)
                                  : AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              agent.isPlaceholder
                                  ? 'Đang thử việc'
                                  : 'Sẵn sàng',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: agent.isPlaceholder
                                    ? AppColors.amber
                                    : AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent.description,
                        style: TextStyle(
                          fontSize: 13,
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
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Capabilities summary
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: agent.capabilities.map((cap) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A35)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '⚡ ${cap.name}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAgentDetail(context, ref, agent),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Xem hồ sơ'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: isRecruited
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Đã vào công ty'),
                        )
                      : AppButton(
                          label: agent.isPlaceholder
                              ? 'Sắp mở tuyển'
                              : 'Tuyển dụng ngay',
                          onPressed: agent.isPlaceholder
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${agent.defaultName} đang được Bộ trưởng vnverse hoàn thiện hồ sơ đào tạo, sếp đón chờ nhé!',
                                      ),
                                    ),
                                  );
                                }
                              : () => _recruit(context, ref, agent),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _recruit(
    BuildContext context,
    WidgetRef ref,
    AgentDefinition agent,
  ) async {
    HapticFeedback.heavyImpact();

    // Check required permissions (e.g. Gmail permissions)
    if (agent.requiredPermissions.isNotEmpty) {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: const Row(
              children: [
                Text('🔒'),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yêu cầu cấp quyền',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'Nhân sự "${agent.defaultName}" cần các quyền hạn sau để thực hiện công việc:\n'
              '${agent.requiredPermissions.map((p) => "• $p").join("\n")}\n\n'
              'Giám đốc vui lòng đăng nhập tài khoản Google và cấp quyền truy cập trước khi chiêu mộ nhân sự này vào vnverse!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Để sau'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vui lòng vào tab Cá nhân để đăng nhập tài khoản Google.',
                      ),
                    ),
                  );
                },
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final success = await ref
        .read(recruitedAgentsProvider.notifier)
        .recruit(agent.id, agent.defaultName);

    if (context.mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: Row(
              children: [
                const Text('🎉'),
                const SizedBox(width: 8),
                Text('Tuyển dụng thành công!'),
              ],
            ),
            content: Text(
              'Chúc mừng Giám đốc đã tuyển mộ thành công **${agent.defaultName}** vào công ty vnverse.\n\nNhân viên mới đã có mặt trong mục **Nhân viên của tôi (Bạn bè)** và sẵn sàng nhận lệnh.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tuyệt vời!'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${agent.defaultName} đã có trong công ty rồi sếp!'),
          ),
        );
      }
    }
  }

  void _showAgentDetail(
    BuildContext context,
    WidgetRef ref,
    AgentDefinition agent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRecruited = ref
        .read(recruitedAgentsProvider.notifier)
        .isRecruited(agent.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        agent.avatarSymbol,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.defaultName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agent.description,
                          style: TextStyle(
                            fontSize: 14,
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
              const SizedBox(height: AppSpacing.xl),

              // Capabilities section
              Text(
                '✅ Có thể làm gì:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...agent.capabilities.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            children: [
                              TextSpan(
                                text: '${c.name}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: c.description),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Limitations section
              Text(
                '❌ Không thể làm gì (Giới hạn năng lực):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...agent.limitations.map(
                (lim) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.red)),
                      Expanded(
                        child: Text(
                          lim,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Permissions section
              Text(
                '🔒 Yêu cầu quyền hạn:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                agent.requiredPermissions.isEmpty
                    ? 'Không yêu cầu bất kỳ quyền truy cập dữ liệu bên ngoài nào.'
                    : 'Yêu cầu: ${agent.requiredPermissions.join(", ")}',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.emerald : Colors.green[700],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Recruit CTA
              isRecruited
                  ? ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Nhân viên đã vào công ty'),
                    )
                  : AppButton(
                      label: agent.isPlaceholder
                          ? 'Đang thử việc (Chưa mở tuyển)'
                          : 'Tuyển dụng nhân viên này',
                      onPressed: agent.isPlaceholder
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              _recruit(context, ref, agent);
                            },
                    ),
            ],
          );
        },
      ),
    );
  }
}

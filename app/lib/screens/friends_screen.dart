import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/agent_chat_screen.dart';
import 'package:smart_inbox_ai/screens/widgets/agent_reminders_sheet.dart';
import 'package:smart_inbox_ai/screens/widgets/naming_dialog.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/app_card.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToMarket;

  const FriendsScreen({super.key, this.onNavigateToMarket});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _showDismissed = false;

  @override
  Widget build(BuildContext context) {
    final recruited = ref.watch(recruitedAgentsProvider);
    final catalog = ref.watch(agentCatalogServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayedAgents = recruited.where((a) {
      if (_showDismissed) return true;
      return a.isDismissed != true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nhân viên của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: recruited.isEmpty
          ? _buildEmptyState(context, isDark)
          : Column(
              children: [
                // Toggle bar to show/hide dismissed employees
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A22)
                        : const Color(0xFFF1F5F9),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x1F000000),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showDismissed
                            ? 'Danh sách: Tất cả nhân viên'
                            : 'Danh sách: Đang làm việc (${displayedAgents.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hiện đã sa thải',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch.adaptive(
                            value: _showDismissed,
                            activeTrackColor: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _showDismissed = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Employee list
                Expanded(
                  child: displayedAgents.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Text(
                              _showDismissed
                                  ? 'Không có nhân viên nào trong danh sách.'
                                  : 'Không có nhân viên nào đang làm việc.\nBật "Hiện đã sa thải" để xem nhân viên cũ.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          itemCount: displayedAgents.length,
                          itemBuilder: (context, index) {
                            final item = displayedAgents[index];
                            final def = catalog.getAgentById(item.agentId);
                            return _buildAgentTile(
                              context,
                              ref,
                              item: item,
                              def: def,
                              isDark: isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.12),
              ),
              child: const Center(
                child: Text('🏢', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Công ty chưa có nhân viên nào!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Giám đốc ơi, phòng làm việc đang vắng vẻ quá. Sếp hãy ghé qua Chợ tuyển dụng để chiêu mộ những nhân tài AI đầu tiên về phụ giúp nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (widget.onNavigateToMarket != null)
              AppButton(
                label: 'Khám phá Chợ tuyển dụng 🚀',
                onPressed: widget.onNavigateToMarket!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentTile(
    BuildContext context,
    WidgetRef ref, {
    required RecruitedAgent item,
    required AgentDefinition? def,
    required bool isDark,
  }) {
    final avatar = def?.avatarSymbol ?? '🤖';
    final desc = def?.description ?? 'Nhân viên AI của vnverse';
    final isDismissed = item.isDismissed;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          HapticFeedback.lightImpact();
          if (def != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AgentChatScreen(
                  agent: def,
                  customName: item.customDisplayName,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDismissed
                        ? [const Color(0xFF3F3F46), const Color(0xFF27272A)]
                        : (isDark
                              ? [
                                  const Color(0xFF312E81),
                                  const Color(0xFF1E1B4B),
                                ]
                              : [
                                  const Color(0xFFEEF2FF),
                                  const Color(0xFFE0E7FF),
                                ]),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    isDismissed ? '🛑' : avatar,
                    style: const TextStyle(fontSize: 26),
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
                            item.customDisplayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isDismissed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDismissed
                                  ? (isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600])
                                  : (isDark
                                        ? Colors.white
                                        : AppColors.textPrimaryLight),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDismissed
                                ? Colors.red.withValues(alpha: 0.15)
                                : AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            isDismissed ? 'Đã sa thải' : 'Đang làm việc',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDismissed
                                  ? Colors.red[400]
                                  : AppColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!isDismissed && def != null) ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          AgentRemindersSheet.show(context, def);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.aiAccentLight.withAlpha(25),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.aiAccentLight.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 13,
                                color: AppColors.aiAccentLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Lịch nhắc 24/24',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.aiAccentDark
                                      : AppColors.aiAccentLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      isDismissed
                          ? 'Đã thôi việc • Chạm để xem lại lịch sử trò chuyện'
                          : 'Nhấn giữ hoặc bấm menu để đổi tên / sa thải',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                onSelected: (value) async {
                  if (value == 'reminders' && def != null) {
                    AgentRemindersSheet.show(context, def);
                  } else if (value == 'rename') {
                    final newName = await NamingDialog.show(
                      context,
                      title: 'Đổi tên nhân viên',
                      currentName: item.customDisplayName,
                      subtitle:
                          'Đặt biệt danh hoặc tên thân mật cho nhân viên này.',
                    );
                    if (newName != null && newName.trim().isNotEmpty) {
                      await ref
                          .read(recruitedAgentsProvider.notifier)
                          .renameAgent(item.agentId, newName);
                    }
                  } else if (value == 'dismiss') {
                    _confirmDismissal(context, ref, item);
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isDismissed && def != null)
                    const PopupMenuItem(
                      value: 'reminders',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 18,
                            color: AppColors.aiAccentLight,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Lịch nhắc nhở (24/24)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đổi tên nhân viên',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDismissed)
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_remove_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Sa thải nhân viên',
                              style: TextStyle(color: Colors.red),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDismissal(
    BuildContext context,
    WidgetRef ref,
    RecruitedAgent item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Sa thải nhân viên?'),
          ],
        ),
        content: Text(
          'Giám đốc có chắc chắn muốn cho "${item.customDisplayName}" thôi việc không?\n\n'
          'Toàn bộ lịch sử trò chuyện vẫn được lưu lại để tra cứu, nhưng nhân viên sẽ không thể nhận thêm tin nhắn mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ bỏ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.heavyImpact();
              await ref
                  .read(recruitedAgentsProvider.notifier)
                  .dismiss(item.agentId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sa thải "${item.customDisplayName}".'),
                  ),
                );
              }
            },
            child: const Text('Xác nhận sa thải'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';
import 'package:smart_inbox_ai/models/reminder_model.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';

/// Modal bottom sheet allowing users to review, toggle, test-run, and manage
/// autonomous background reminder tasks for an agent.
class AgentRemindersSheet extends ConsumerStatefulWidget {
  final AgentDefinition agent;

  const AgentRemindersSheet({super.key, required this.agent});

  static Future<void> show(BuildContext context, AgentDefinition agent) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentRemindersSheet(agent: agent),
    );
  }

  @override
  ConsumerState<AgentRemindersSheet> createState() =>
      _AgentRemindersSheetState();
}

class _AgentRemindersSheetState extends ConsumerState<AgentRemindersSheet> {
  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(
      agentRemindersFamilyProvider(widget.agent.id),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.primaryContainerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.agent.avatarSymbol,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch nhắc nhở • ${widget.agent.defaultName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tác vụ chạy ngầm tự chủ 24/24',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Autonomous banner info
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.aiAccentLight.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.aiAccentLight.withAlpha(60),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: AppColors.aiAccentLight,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nhân sự này sẽ tự động chạy ngầm, gửi tin nhắn vào khung chat và thông báo cho Giám đốc khi đến giờ đã hẹn.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reminders list
          Flexible(
            child: Builder(
              builder: (context) {
                if (remindersState.isLoading &&
                    remindersState.reminders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (remindersState.reminders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xxl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_paused_outlined,
                          size: 56,
                          color: theme.colorScheme.outline.withAlpha(150),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Chưa có lịch nhắc nhở nào',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Bạn có thể yêu cầu nhân sự trong khung chat hoặc nhấn nút thêm mới bên dưới.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  shrinkWrap: true,
                  itemCount: remindersState.reminders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, index) {
                    final item = remindersState.reminders[index];
                    return _buildReminderCard(context, item);
                  },
                );
              },
            ),
          ),

          // Bottom Action: Add reminder button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_alarm),
              label: const Text('Thêm lịch nhắc thủ công'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showAddReminderDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, AgentReminder reminder) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isEnabled
              ? theme.colorScheme.primary.withAlpha(50)
              : theme.colorScheme.outline.withAlpha(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Switch Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminder.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: reminder.isEnabled
                          ? null
                          : TextDecoration.lineThrough,
                      color: reminder.isEnabled
                          ? null
                          : theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: reminder.isEnabled,
                  activeTrackColor: AppColors.primaryLight,
                  onChanged: (val) {
                    ref
                        .read(
                          agentRemindersFamilyProvider(widget.agent.id)
                              .notifier,
                        )
                        .toggleReminder(reminder.id, val);
                  },
                ),
              ],
            ),

            if (reminder.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reminder.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Schedule & Time Badge
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.targetTime,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.repeat, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        reminder.schedule.toReadableText(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: 4),

            // Actions row: Test run & Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Chạy thử ngay'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.aiAccentLight,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await ref
                        .read(
                          agentRemindersFamilyProvider(widget.agent.id)
                              .notifier,
                        )
                        .testRunReminder(reminder.id);
                    if (result != null && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(result),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Xoá lịch nhắc',
                  onPressed: () => _confirmDeleteReminder(context, reminder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReminder(BuildContext context, AgentReminder reminder) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá lịch nhắc?'),
        content: Text('Sếp có chắc muốn xoá "${reminder.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(agentRemindersFamilyProvider(widget.agent.id).notifier)
                  .deleteReminder(reminder.id);
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleController = TextEditingController(
      text: widget.agent.id == 'thay_cung'
          ? 'Nhắc ngày mùng 1 & ngày rằm 15'
          : 'Nhắc việc định kỳ',
    );
    final occasionController = TextEditingController();
    var selectedTime = const TimeOfDay(hour: 7, minute: 0);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm lịch nhắc mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhắc nhở',
                    hintText: 'VD: Nhắc thắp hương mùng 1',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: occasionController,
                  decoration: const InputDecoration(
                    labelText: 'Dịp / Ghi chú (tuỳ chọn)',
                    hintText: 'VD: Sóc vọng hoặc Giỗ cụ',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Giờ nhắc: '),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.access_time, size: 16),
                      label: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                final timeStr =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                final payload = {
                  'title': titleController.text.trim().isEmpty
                      ? 'Lịch nhắc mới'
                      : titleController.text.trim(),
                  'description': 'Lập lịch tự động bởi người dùng',
                  'schedule': {
                    'type': 'lunar_monthly',
                    'days': [1, 15],
                  },
                  'target_time': timeStr,
                  'occasion': occasionController.text.trim().isEmpty
                      ? null
                      : occasionController.text.trim(),
                };
                ref
                    .read(
                      agentRemindersFamilyProvider(widget.agent.id).notifier,
                    )
                    .createReminder(payload);
                Navigator.of(ctx).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

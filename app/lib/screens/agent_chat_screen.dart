import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';
import 'package:smart_inbox_ai/models/assistant_chat.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/widgets/agent_reminders_sheet.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';

class AgentChatScreen extends ConsumerStatefulWidget {
  final AgentDefinition agent;
  final String customName;

  const AgentChatScreen({
    super.key,
    required this.agent,
    required this.customName,
  });

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(agentChatFamilyProvider(widget.agent.id).notifier)
          .initialize(
            'Kính chào Giám đốc! Em là ${widget.customName} của công ty vnverse. '
            'Em phụ trách: ${widget.agent.capabilities.map((c) => c.name).join(", ")}. '
            'Hôm nay sếp cần em hỗ trợ việc gì ạ?',
          );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    final locale = ref.read(localeProvider).languageCode;
    ref
        .read(agentChatFamilyProvider(widget.agent.id).notifier)
        .sendMessage(text, locale: locale);
    HapticFeedback.lightImpact();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(agentChatFamilyProvider(widget.agent.id));
    final recruitedList = ref.watch(recruitedAgentsProvider);
    final recruitedAgent = recruitedList.cast<RecruitedAgent?>().firstWhere(
      (a) => a?.agentId == widget.agent.id,
      orElse: () => null,
    );
    final isDismissed = recruitedAgent?.isDismissed ?? false;

    ref.listen<ChatAssistantState>(agentChatFamilyProvider(widget.agent.id), (
      prev,
      next,
    ) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.agent.avatarSymbol,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDismissed ? Colors.red : AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDismissed
                            ? 'Đã sa thải • Xem lại lịch sử'
                            : 'Đang trực tuyến • vnverse',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDismissed
                              ? Colors.red[300]
                              : (isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isDismissed)
            IconButton(
              icon: const Icon(Icons.bolt, color: AppColors.aiAccentLight),
              tooltip: 'Lịch nhắc 24/24',
              onPressed: () {
                AgentRemindersSheet.show(context, widget.agent);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Notice banner of agent capability
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E1E28) : const Color(0xFFEEF2FF),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nhân viên chuyên trách: ${widget.agent.category == "vietnamese_culture" ? "Văn hoá & Tâm linh" : widget.agent.category}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return _buildMessageBubble(context, msg, isDark);
              },
            ),
          ),

          if (chatState.isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.customName} đang soạn câu trả lời...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),

          // Quick Suggestion Chips
          if (!isDismissed) _buildQuickChips(isDark),

          // Input field or Dismissed Banner
          if (isDismissed)
            _buildDismissedInputBanner(context, isDark)
          else
            _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildDismissedInputBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F24) : const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nhân viên này đã bị sa thải. Giám đốc chỉ có thể xem lại lịch sử trò chuyện.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips(bool isDark) {
    final chips = [
      'Bao giờ đến ngày rằm?',
      'Bài cúng mùng 1 thế nào?',
      'Tết Đoan Ngọ là ngày nào?',
      'Mâm lễ cúng gồm những gì?',
      'Nhắc ngày mùng 1 & rằm',
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final text = chips[index];
          return ActionChip(
            label: Text(text),
            backgroundColor: isDark
                ? const Color(0xFF26262E)
                : const Color(0xFFF1F5F9),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            onPressed: () => _sendMessage(text),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    AssistantMessage msg,
    bool isDark,
  ) {
    final isUser = msg.role == 'user';
    final isOut = msg.recommendAgentId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.agent.avatarSymbol,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : (isOut
                          ? (isDark
                                ? const Color(0xFF3A2424)
                                : const Color(0xFFFFF1F1))
                          : (isDark ? const Color(0xFF24242C) : Colors.white)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
                ),
                border: !isUser && !isOut
                    ? Border.all(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x1F000000),
                        width: 0.8,
                      )
                    : (isOut
                          ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                          : null),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOut)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Chuyển tiếp qua Trợ lý Giám đốc',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : (isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight),
                    ),
                  ),
                  if (msg.interactiveConfig != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InteractiveConfigBubble(
                      config: msg.interactiveConfig!,
                      isDark: isDark,
                      onConfirm: (selectionText) => _sendMessage(selectionText),
                      onOpenManager: () =>
                          AgentRemindersSheet.show(context, widget.agent),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Nhắn cho ${widget.customName}...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A35)
                    : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _sendMessage(),
            icon: const Icon(Icons.send_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveConfigBubble extends StatefulWidget {
  final InteractiveConfigPrompt config;
  final bool isDark;
  final ValueChanged<String> onConfirm;
  final VoidCallback onOpenManager;

  const _InteractiveConfigBubble({
    required this.config,
    required this.isDark,
    required this.onConfirm,
    required this.onOpenManager,
  });

  @override
  State<_InteractiveConfigBubble> createState() =>
      _InteractiveConfigBubbleState();
}

class _InteractiveConfigBubbleState extends State<_InteractiveConfigBubble> {
  late Set<String> _selectedIds;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.config.options
        .where((opt) => opt.defaultChecked)
        .map((opt) => opt.id)
        .toSet();
  }

  void _toggleOption(String id) {
    if (_isSubmitted) return;
    setState(() {
      if (widget.config.isMultiSelect) {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      } else {
        _selectedIds = {id};
      }
    });
  }

  void _handleConfirm() {
    if (_isSubmitted) return;
    setState(() {
      _isSubmitted = true;
    });

    final selectedLabels = widget.config.options
        .where((opt) => _selectedIds.contains(opt.id))
        .map((opt) => opt.label)
        .toList();

    String message;
    if (selectedLabels.isEmpty) {
      message =
          'Tôi không chọn ngày nhắc nào. Vui lòng hướng dẫn tôi cấu hình lại.';
    } else {
      message =
          'Tôi chọn lịch nhắc: ${selectedLabels.join(", ")}. Hãy lưu lịch nhắc nhở này cho tôi nhé!';
    }
    widget.onConfirm(message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = widget.isDark
        ? AppColors.aiAccentDark.withAlpha(60)
        : AppColors.aiAccentLight.withAlpha(80);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1B1B22)
            : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available,
                size: 18,
                color: AppColors.aiAccentLight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.config.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.isDark
                        ? Colors.white
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.config.options.map((opt) {
            final isChecked = _selectedIds.contains(opt.id);
            return InkWell(
              onTap: () => _toggleOption(opt.id),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isChecked,
                        activeColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: _isSubmitted
                            ? null
                            : (_) => _toggleOption(opt.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isChecked
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: widget.isDark
                              ? (isChecked ? Colors.white : Colors.grey[400])
                              : (isChecked
                                    ? AppColors.textPrimaryLight
                                    : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    _isSubmitted ? Icons.check : Icons.alarm_on,
                    size: 16,
                  ),
                  label: Text(
                    _isSubmitted
                        ? 'Đã gửi lựa chọn'
                        : widget.config.confirmLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitted ? null : _handleConfirm,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18),
                tooltip: 'Mở chi tiết lịch nhắc',
                onPressed: widget.onOpenManager,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

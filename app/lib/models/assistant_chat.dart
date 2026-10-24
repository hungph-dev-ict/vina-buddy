// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';

enum AssistantIntent {
  recommend_agent,
  chitchat,
  out_of_scope,
  stats,
  classify,
  label,
  other,
}

class CategoryStatItem {
  final String categoryId;
  final String categoryName;
  final int count;
  final int unread;
  final String colorHex;

  const CategoryStatItem({
    required this.categoryId,
    required this.categoryName,
    required this.count,
    required this.unread,
    required this.colorHex,
  });

  factory CategoryStatItem.fromJson(Map<String, dynamic> json) {
    return CategoryStatItem(
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      colorHex: json['color_hex'] as String? ?? '#6366F1',
    );
  }
}

class TopSenderItem {
  final String senderName;
  final String senderEmail;
  final int count;

  const TopSenderItem({
    required this.senderName,
    required this.senderEmail,
    required this.count,
  });

  factory TopSenderItem.fromJson(Map<String, dynamic> json) {
    return TopSenderItem(
      senderName: json['sender_name'] as String? ?? '',
      senderEmail: json['sender_email'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class EmailStatsData {
  final int totalEmails;
  final int unreadEmails;
  final int readEmails;
  final List<CategoryStatItem> categories;
  final List<TopSenderItem> topSenders;

  const EmailStatsData({
    required this.totalEmails,
    required this.unreadEmails,
    required this.readEmails,
    required this.categories,
    required this.topSenders,
  });

  factory EmailStatsData.fromJson(Map<String, dynamic> json) {
    return EmailStatsData(
      totalEmails: json['total_emails'] as int? ?? 0,
      unreadEmails: json['unread_emails'] as int? ?? 0,
      readEmails: json['read_emails'] as int? ?? 0,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryStatItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topSenders:
          (json['top_senders'] as List<dynamic>?)
              ?.map((e) => TopSenderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ClassifyCategoryItem {
  final String categoryId;
  final String categoryName;
  final String description;
  final int matchedCount;
  final List<String> sampleSenders;
  final String suggestedLabel;

  const ClassifyCategoryItem({
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.matchedCount,
    required this.sampleSenders,
    required this.suggestedLabel,
  });

  factory ClassifyCategoryItem.fromJson(Map<String, dynamic> json) {
    return ClassifyCategoryItem(
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      matchedCount: json['matched_count'] as int? ?? 0,
      sampleSenders:
          (json['sample_senders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedLabel: json['suggested_label'] as String? ?? '',
    );
  }
}

class EmailClassifyData {
  final int totalAnalyzed;
  final List<ClassifyCategoryItem> categories;

  const EmailClassifyData({
    required this.totalAnalyzed,
    required this.categories,
  });

  factory EmailClassifyData.fromJson(Map<String, dynamic> json) {
    return EmailClassifyData(
      totalAnalyzed: json['total_analyzed'] as int? ?? 0,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map(
                (e) => ClassifyCategoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class CleanupProposalData {
  final String ruleId;
  final String ruleName;
  final String targetLabel;
  final int matchedCount;
  final List<String> sampleSubjects;
  final List<String> matchedEmailIds;
  final String explanation;
  final bool isApplied;

  const CleanupProposalData({
    required this.ruleId,
    required this.ruleName,
    required this.targetLabel,
    required this.matchedCount,
    required this.sampleSubjects,
    this.matchedEmailIds = const ['email_news_001', 'email_news_002'],
    required this.explanation,
    this.isApplied = false,
  });

  CleanupProposalData copyWith({bool? isApplied}) {
    return CleanupProposalData(
      ruleId: ruleId,
      ruleName: ruleName,
      targetLabel: targetLabel,
      matchedCount: matchedCount,
      sampleSubjects: sampleSubjects,
      matchedEmailIds: matchedEmailIds,
      explanation: explanation,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  factory CleanupProposalData.fromJson(Map<String, dynamic> json) {
    return CleanupProposalData(
      ruleId: json['rule_id'] as String? ?? '',
      ruleName: json['rule_name'] as String? ?? '',
      targetLabel: json['target_label'] as String? ?? '',
      matchedCount: json['matched_count'] as int? ?? 0,
      sampleSubjects:
          (json['sample_subjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      matchedEmailIds:
          (json['matched_email_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['email_news_001', 'email_news_002'],
      explanation: json['explanation'] as String? ?? '',
      isApplied: false,
    );
  }
}

class InteractiveOption {
  final String id;
  final String label;
  final bool defaultChecked;

  const InteractiveOption({
    required this.id,
    required this.label,
    this.defaultChecked = false,
  });

  factory InteractiveOption.fromJson(Map<String, dynamic> json) {
    return InteractiveOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      defaultChecked: json['default_checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'default_checked': defaultChecked,
  };
}

class InteractiveConfigPrompt {
  final String configType;
  final String title;
  final bool isMultiSelect;
  final List<InteractiveOption> options;
  final String confirmLabel;

  const InteractiveConfigPrompt({
    this.configType = 'reminder_quick_setup',
    this.title = 'Chọn lịch nhắc tự động',
    this.isMultiSelect = true,
    this.options = const [],
    this.confirmLabel = 'Xác nhận lịch nhắc',
  });

  factory InteractiveConfigPrompt.fromJson(Map<String, dynamic> json) {
    return InteractiveConfigPrompt(
      configType: json['config_type'] as String? ?? 'reminder_quick_setup',
      title: json['title'] as String? ?? 'Chọn lịch nhắc tự động',
      isMultiSelect: json['is_multi_select'] as bool? ?? true,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => InteractiveOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      confirmLabel: json['confirm_label'] as String? ?? 'Xác nhận lịch nhắc',
    );
  }

  Map<String, dynamic> toJson() => {
    'config_type': configType,
    'title': title,
    'is_multi_select': isMultiSelect,
    'options': options.map((e) => e.toJson()).toList(),
    'confirm_label': confirmLabel,
  };
}

@immutable
class AssistantMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final AssistantIntent intent;
  final String actionType;
  final EmailStatsData? stats;
  final EmailClassifyData? classification;
  final CleanupProposalData? proposal;
  final List<String> suggestedActions;
  final double? confidence;
  final String? llmProvider;
  final bool isProcessing;

  final String? agentId;
  final String? recommendAgentId;
  final String? handoffReason;
  final InteractiveConfigPrompt? interactiveConfig;

  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.intent = AssistantIntent.other,
    this.actionType = 'text',
    this.stats,
    this.classification,
    this.proposal,
    this.suggestedActions = const ['stats', 'classify', 'label'],
    this.confidence,
    this.llmProvider,
    this.isProcessing = false,
    this.agentId,
    this.recommendAgentId,
    this.handoffReason,
    this.interactiveConfig,
  });

  AssistantMessage copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
    AssistantIntent? intent,
    String? actionType,
    EmailStatsData? stats,
    EmailClassifyData? classification,
    CleanupProposalData? proposal,
    List<String>? suggestedActions,
    double? confidence,
    String? llmProvider,
    bool? isProcessing,
    String? agentId,
    String? recommendAgentId,
    String? handoffReason,
    InteractiveConfigPrompt? interactiveConfig,
  }) {
    return AssistantMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      intent: intent ?? this.intent,
      actionType: actionType ?? this.actionType,
      stats: stats ?? this.stats,
      classification: classification ?? this.classification,
      proposal: proposal ?? this.proposal,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      confidence: confidence ?? this.confidence,
      llmProvider: llmProvider ?? this.llmProvider,
      isProcessing: isProcessing ?? this.isProcessing,
      agentId: agentId ?? this.agentId,
      recommendAgentId: recommendAgentId ?? this.recommendAgentId,
      handoffReason: handoffReason ?? this.handoffReason,
      interactiveConfig: interactiveConfig ?? this.interactiveConfig,
    );
  }

  factory AssistantMessage.fromChatResponse({
    required String id,
    required Map<String, dynamic> json,
    String? agentId,
  }) {
    final intentStr = json['intent'] as String? ?? 'other';
    final intent = AssistantIntent.values.firstWhere(
      (e) => e.name == intentStr,
      orElse: () => AssistantIntent.other,
    );

    return AssistantMessage(
      id: id,
      role: 'assistant',
      text: json['reply'] as String? ?? '',
      timestamp: DateTime.now(),
      intent: intent,
      actionType: json['action_type'] as String? ?? 'text',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.95,
      llmProvider: json['llm_provider'] as String? ?? 'Ollama (qwen2.5:3b)',
      stats: json['stats'] != null
          ? EmailStatsData.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      classification: json['classification'] != null
          ? EmailClassifyData.fromJson(
              json['classification'] as Map<String, dynamic>,
            )
          : null,
      proposal: json['proposal'] != null
          ? CleanupProposalData.fromJson(
              json['proposal'] as Map<String, dynamic>,
            )
          : null,
      suggestedActions:
          (json['suggested_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['stats', 'classify', 'label'],
      isProcessing: false,
      agentId: agentId ?? json['agent_id'] as String?,
      recommendAgentId: json['recommend_agent_id'] as String?,
      handoffReason: json['handoff'] != null
          ? (json['handoff'] as Map<String, dynamic>)['reason'] as String?
          : null,
      interactiveConfig: json['interactive_config'] != null
          ? InteractiveConfigPrompt.fromJson(
              json['interactive_config'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

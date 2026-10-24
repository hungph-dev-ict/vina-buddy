import 'package:flutter/foundation.dart';

@immutable
class ReminderSchedule {
  final String type; // 'lunar_monthly', 'lunar_yearly', 'solar_weekly', 'solar_monthly', 'solar_once'
  final List<int> days;
  final int? month;
  final int? weekday;

  const ReminderSchedule({
    required this.type,
    this.days = const [],
    this.month,
    this.weekday,
  });

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    return ReminderSchedule(
      type: json['type'] as String? ?? 'lunar_monthly',
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      month: (json['month'] as num?)?.toInt(),
      weekday: (json['weekday'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'days': days,
      if (month != null) 'month': month,
      if (weekday != null) 'weekday': weekday,
    };
  }

  String toReadableText() {
    if (type == 'lunar_monthly') {
      if (days.contains(1) && days.contains(15)) {
        return 'Mùng 1 & Ngày rằm (15) Âm lịch hàng tháng';
      }
      return 'Ngày ${days.join(", ")} Âm lịch hàng tháng';
    }
    if (type == 'lunar_yearly') {
      return 'Ngày ${days.join(", ")}/${month ?? ""} Âm lịch hàng năm';
    }
    if (type == 'solar_weekly') {
      return 'Thứ $weekday hàng tuần';
    }
    return 'Định kỳ ngày ${days.join(", ")}';
  }
}

@immutable
class AgentReminder {
  final String id;
  final String agentId;
  final String title;
  final String description;
  final ReminderSchedule schedule;
  final String targetTime;
  final String? occasion;
  final Map<String, dynamic> customPayload;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastRunAt;

  const AgentReminder({
    required this.id,
    required this.agentId,
    required this.title,
    required this.description,
    required this.schedule,
    required this.targetTime,
    this.occasion,
    this.customPayload = const {},
    this.isEnabled = true,
    required this.createdAt,
    this.lastRunAt,
  });

  factory AgentReminder.fromJson(Map<String, dynamic> json) {
    return AgentReminder(
      id: json['id'] as String? ?? '',
      agentId: json['agent_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      schedule: ReminderSchedule.fromJson(
        json['schedule'] as Map<String, dynamic>? ?? {},
      ),
      targetTime: json['target_time'] as String? ?? '07:00',
      occasion: json['occasion'] as String?,
      customPayload:
          json['custom_payload'] as Map<String, dynamic>? ?? const {},
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastRunAt: json['last_run_at'] != null
          ? DateTime.tryParse(json['last_run_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'title': title,
      'description': description,
      'schedule': schedule.toJson(),
      'target_time': targetTime,
      if (occasion != null) 'occasion': occasion,
      'custom_payload': customPayload,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
      if (lastRunAt != null) 'last_run_at': lastRunAt!.toIso8601String(),
    };
  }

  AgentReminder copyWith({
    String? id,
    String? agentId,
    String? title,
    String? description,
    ReminderSchedule? schedule,
    String? targetTime,
    String? occasion,
    Map<String, dynamic>? customPayload,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastRunAt,
  }) {
    return AgentReminder(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      title: title ?? this.title,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      targetTime: targetTime ?? this.targetTime,
      occasion: occasion ?? this.occasion,
      customPayload: customPayload ?? this.customPayload,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }
}

class RuleConditionModel {
  final String field;
  final String operator;
  final String value;

  const RuleConditionModel({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory RuleConditionModel.fromJson(Map<String, dynamic> json) {
    return RuleConditionModel(
      field: json['field'] as String? ?? 'from',
      operator: json['operator'] as String? ?? 'contains',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': operator,
    'value': value,
  };
}

class RuleActionModel {
  final String type;
  final String label;

  const RuleActionModel({required this.type, required this.label});

  factory RuleActionModel.fromJson(Map<String, dynamic> json) {
    return RuleActionModel(
      type: json['type'] as String? ?? 'add_label',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'label': label};
}

class RuleModel {
  final String id;
  final String name;
  final String naturalLanguage;
  final List<RuleConditionModel> conditions;
  final List<RuleActionModel> actions;
  final int priority;
  final bool enabled;
  final double llmConfidence;
  final String llmProvider;
  final bool isUncertain;
  final String createdAt;
  final List<RuleModel> subRules;

  const RuleModel({
    required this.id,
    required this.name,
    required this.naturalLanguage,
    required this.conditions,
    required this.actions,
    this.priority = 1,
    this.enabled = true,
    this.llmConfidence = 1.0,
    this.llmProvider = 'ollama',
    this.isUncertain = false,
    this.createdAt = '',
    this.subRules = const [],
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Custom Rule',
      naturalLanguage: json['natural_language'] as String? ?? '',
      conditions:
          (json['conditions'] as List<dynamic>?)
              ?.map(
                (e) => RuleConditionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => RuleActionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priority: json['priority'] as int? ?? 1,
      enabled: json['enabled'] as bool? ?? true,
      llmConfidence: (json['llm_confidence'] as num?)?.toDouble() ?? 1.0,
      llmProvider: json['llm_provider'] as String? ?? 'ollama',
      isUncertain: json['is_uncertain'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      subRules:
          (json['sub_rules'] as List<dynamic>?)
              ?.map((e) => RuleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  RuleModel copyWith({bool? enabled, List<RuleModel>? subRules}) {
    return RuleModel(
      id: id,
      name: name,
      naturalLanguage: naturalLanguage,
      conditions: conditions,
      actions: actions,
      priority: priority,
      enabled: enabled ?? this.enabled,
      llmConfidence: llmConfidence,
      llmProvider: llmProvider,
      isUncertain: isUncertain,
      createdAt: createdAt,
      subRules: subRules ?? this.subRules,
    );
  }
}

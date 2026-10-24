class AgentPersonality {
  final String tone;
  final String style;

  const AgentPersonality({required this.tone, required this.style});

  factory AgentPersonality.fromJson(Map<String, dynamic> json) {
    return AgentPersonality(
      tone: json['tone'] as String? ?? 'humorous',
      style: json['style'] as String? ?? 'playful_vietnamese_office_humor',
    );
  }

  Map<String, dynamic> toJson() => {'tone': tone, 'style': style};
}

class AgentCapability {
  final String id;
  final String name;
  final String description;
  final List<String> supportedIntents;
  final bool requiresExternalPermission;

  const AgentCapability({
    required this.id,
    required this.name,
    required this.description,
    this.supportedIntents = const [],
    this.requiresExternalPermission = false,
  });

  factory AgentCapability.fromJson(Map<String, dynamic> json) {
    return AgentCapability(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      supportedIntents:
          (json['supportedIntents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiresExternalPermission:
          json['requiresExternalPermission'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'supportedIntents': supportedIntents,
    'requiresExternalPermission': requiresExternalPermission,
  };
}

class AgentDefinition {
  final String id;
  final String defaultName;
  final String category;
  final String description;
  final String avatarSymbol;
  final AgentPersonality personality;
  final List<AgentCapability> capabilities;
  final List<String> limitations;
  final List<String> requiredPermissions;
  final int version;
  final bool isPlaceholder;

  const AgentDefinition({
    required this.id,
    required this.defaultName,
    required this.category,
    required this.description,
    this.avatarSymbol = '🤖',
    required this.personality,
    this.capabilities = const [],
    this.limitations = const [],
    this.requiredPermissions = const [],
    this.version = 1,
    this.isPlaceholder = false,
  });

  factory AgentDefinition.fromJson(Map<String, dynamic> json) {
    return AgentDefinition(
      id: json['id'] as String? ?? '',
      defaultName: json['defaultName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      avatarSymbol: json['avatarSymbol'] as String? ?? '🤖',
      personality: json['personality'] != null
          ? AgentPersonality.fromJson(
              json['personality'] as Map<String, dynamic>,
            )
          : const AgentPersonality(
              tone: 'humorous',
              style: 'playful_vietnamese_office_humor',
            ),
      capabilities:
          (json['capabilities'] as List<dynamic>?)
              ?.map((e) => AgentCapability.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      limitations:
          (json['limitations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiredPermissions:
          (json['requiredPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      version: json['version'] as int? ?? 1,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'defaultName': defaultName,
    'category': category,
    'description': description,
    'avatarSymbol': avatarSymbol,
    'personality': personality.toJson(),
    'capabilities': capabilities.map((c) => c.toJson()).toList(),
    'limitations': limitations,
    'requiredPermissions': requiredPermissions,
    'version': version,
    'isPlaceholder': isPlaceholder,
  };
}

class RecruitedAgent {
  final String agentId;
  final String customDisplayName;
  final DateTime recruitedAt;
  final bool? _isDismissed;
  final DateTime? dismissedAt;

  bool get isDismissed => _isDismissed ?? false;

  const RecruitedAgent({
    required this.agentId,
    required this.customDisplayName,
    required this.recruitedAt,
    bool? isDismissed,
    this.dismissedAt,
  }) : _isDismissed = isDismissed ?? false;

  factory RecruitedAgent.fromJson(Map<String, dynamic> json) {
    return RecruitedAgent(
      agentId: json['agentId'] as String? ?? '',
      customDisplayName: json['customDisplayName'] as String? ?? '',
      recruitedAt: json['recruitedAt'] != null
          ? DateTime.tryParse(json['recruitedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isDismissed: json['isDismissed'] as bool? ?? false,
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.tryParse(json['dismissedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'customDisplayName': customDisplayName,
    'recruitedAt': recruitedAt.toIso8601String(),
    'isDismissed': isDismissed,
    'dismissedAt': dismissedAt?.toIso8601String(),
  };

  RecruitedAgent copyWith({
    String? customDisplayName,
    bool? isDismissed,
    DateTime? dismissedAt,
  }) {
    return RecruitedAgent(
      agentId: agentId,
      customDisplayName: customDisplayName ?? this.customDisplayName,
      recruitedAt: recruitedAt,
      isDismissed: isDismissed ?? this.isDismissed,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }
}

class AgentHandoff {
  final bool matched;
  final String? capabilityId;
  final double confidence;
  final String reason;
  final bool handoffRequired;
  final String sourceAgentId;
  final String userQuery;
  final String? recommendedAgentId;

  const AgentHandoff({
    required this.matched,
    this.capabilityId,
    this.confidence = 1.0,
    required this.reason,
    required this.handoffRequired,
    required this.sourceAgentId,
    required this.userQuery,
    this.recommendedAgentId,
  });

  factory AgentHandoff.fromJson(Map<String, dynamic> json) {
    return AgentHandoff(
      matched: json['matched'] as bool? ?? false,
      capabilityId: json['capabilityId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      reason: json['reason'] as String? ?? '',
      handoffRequired: json['handoffRequired'] as bool? ?? false,
      sourceAgentId: json['sourceAgentId'] as String? ?? '',
      userQuery: json['userQuery'] as String? ?? '',
      recommendedAgentId: json['recommendedAgentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'matched': matched,
    'capabilityId': capabilityId,
    'confidence': confidence,
    'reason': reason,
    'handoffRequired': handoffRequired,
    'sourceAgentId': sourceAgentId,
    'userQuery': userQuery,
    'recommendedAgentId': recommendedAgentId,
  };
}

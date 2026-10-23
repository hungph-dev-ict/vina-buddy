import 'package:smart_inbox_ai/models/rule_model.dart';

class ClassifiedMatchModel {
  final String emailId;
  final String subject;
  final String fromEmail;
  final List<RuleActionModel> proposedActions;
  final double confidence;
  final bool isUncertain;
  final List<String> matchedConditions;

  const ClassifiedMatchModel({
    required this.emailId,
    required this.subject,
    required this.fromEmail,
    required this.proposedActions,
    required this.confidence,
    this.isUncertain = false,
    this.matchedConditions = const [],
  });

  factory ClassifiedMatchModel.fromJson(Map<String, dynamic> json) {
    return ClassifiedMatchModel(
      emailId: json['email_id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      fromEmail: json['from_email'] as String? ?? '',
      proposedActions: (json['proposed_actions'] as List<dynamic>?)
              ?.map((e) => RuleActionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isUncertain: json['is_uncertain'] as bool? ?? false,
      matchedConditions: (json['matched_conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class PreviewModel {
  final String ruleId;
  final String ruleName;
  final List<ClassifiedMatchModel> matches;
  final int totalMatches;
  final int totalEmailsEvaluated;
  final int evaluationTimeMs;

  const PreviewModel({
    required this.ruleId,
    required this.ruleName,
    required this.matches,
    required this.totalMatches,
    required this.totalEmailsEvaluated,
    required this.evaluationTimeMs,
  });

  factory PreviewModel.fromJson(Map<String, dynamic> json) {
    return PreviewModel(
      ruleId: json['rule_id'] as String? ?? '',
      ruleName: json['rule_name'] as String? ?? '',
      matches: (json['matches'] as List<dynamic>?)
              ?.map((e) =>
                  ClassifiedMatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalMatches: json['total_matches'] as int? ?? 0,
      totalEmailsEvaluated: json['total_emails_evaluated'] as int? ?? 0,
      evaluationTimeMs: json['evaluation_time_ms'] as int? ?? 0,
    );
  }
}

class ApplySummaryModel {
  final int total;
  final int succeeded;
  final int failed;

  const ApplySummaryModel({
    required this.total,
    required this.succeeded,
    required this.failed,
  });

  factory ApplySummaryModel.fromJson(Map<String, dynamic> json) {
    return ApplySummaryModel(
      total: json['total'] as int? ?? 0,
      succeeded: json['succeeded'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
    );
  }
}

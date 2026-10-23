import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/models/preview_model.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';

void main() {
  group('EmailItem Model', () {
    test('parses json correctly', () {
      final json = {
        'id': 'msg_001',
        'thread_id': 'th_001',
        'from_email': 'test@example.com',
        'from_name': 'Test User',
        'subject': 'Order Shipped',
        'snippet': 'Your order has shipped',
        'date': '2026-10-23T10:00:00Z',
        'labels': ['INBOX', 'UNREAD'],
        'has_attachments': false,
      };

      final item = EmailItem.fromJson(json);
      expect(item.id, 'msg_001');
      expect(item.fromName, 'Test User');
      expect(item.labels, contains('INBOX'));
    });
  });

  group('RuleModel', () {
    test('parses structured conditions, actions, and uncertainty', () {
      final json = {
        'id': 'rule_100',
        'name': 'Newsletters',
        'natural_language': 'Label newsletters',
        'conditions': [
          {'field': 'from', 'operator': 'contains', 'value': 'newsletter'}
        ],
        'actions': [
          {'type': 'add_label', 'label': 'Newsletters'}
        ],
        'priority': 1,
        'enabled': true,
        'llm_confidence': 0.60,
        'llm_provider': 'ollama',
        'is_uncertain': true,
      };

      final rule = RuleModel.fromJson(json);
      expect(rule.name, 'Newsletters');
      expect(rule.conditions.length, 1);
      expect(rule.actions[0].label, 'Newsletters');
      expect(rule.isUncertain, true);
    });

    test('copyWith updates enabled state', () {
      const rule = RuleModel(
        id: 'r1',
        name: 'Test',
        naturalLanguage: 'Test',
        conditions: [],
        actions: [],
        enabled: true,
      );

      final toggled = rule.copyWith(enabled: false);
      expect(toggled.enabled, false);
      expect(toggled.id, 'r1');
    });

    test('parses subRules for compound multi-intent rules', () {
      final json = {
        'id': 'rule_1',
        'name': 'TLDR to Spam',
        'natural_language': 'emails from tldr are spam and emails from GitHub are source code',
        'conditions': [
          {'field': 'from', 'operator': 'contains', 'value': 'tldr'}
        ],
        'actions': [
          {'type': 'add_label', 'label': 'Spam'}
        ],
        'sub_rules': [
          {
            'id': 'rule_2',
            'name': 'GitHub to Source Code',
            'natural_language': 'emails from tldr are spam and emails from GitHub are source code',
            'conditions': [
              {'field': 'from', 'operator': 'contains', 'value': 'github'}
            ],
            'actions': [
              {'type': 'add_label', 'label': 'Source Code'}
            ],
          }
        ],
      };

      final rule = RuleModel.fromJson(json);
      expect(rule.id, 'rule_1');
      expect(rule.conditions[0].value, 'tldr');
      expect(rule.actions[0].label, 'Spam');
      expect(rule.subRules.length, 1);
      expect(rule.subRules[0].id, 'rule_2');
      expect(rule.subRules[0].conditions[0].value, 'github');
      expect(rule.subRules[0].actions[0].label, 'Source Code');
    });
  });

  group('PreviewModel', () {
    test('parses matches and evaluation metrics', () {
      final json = {
        'rule_id': 'r1',
        'rule_name': 'Rule 1',
        'matches': [
          {
            'email_id': 'email_1',
            'subject': 'Subject',
            'from_email': 'sender@test.com',
            'proposed_actions': [
              {'type': 'add_label', 'label': 'Shopping'}
            ],
            'confidence': 0.95,
            'is_uncertain': false,
            'matched_conditions': ['from contains amazon'],
          }
        ],
        'total_matches': 1,
        'total_emails_evaluated': 50,
        'evaluation_time_ms': 120,
      };

      final preview = PreviewModel.fromJson(json);
      expect(preview.totalMatches, 1);
      expect(preview.matches[0].emailId, 'email_1');
      expect(preview.matches[0].proposedActions[0].label, 'Shopping');
    });
  });
}

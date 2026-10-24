import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/assistant_chat.dart';

void main() {
  group('AssistantChat Models Test', () {
    test('AssistantMessage.fromChatResponse parses stats intent correctly', () {
      final json = {
        'reply': 'Đây là thống kê email của bạn',
        'intent': 'stats',
        'action_type': 'stats',
        'stats': {
          'total_emails': 10,
          'unread_emails': 4,
          'read_emails': 6,
          'categories': [
            {
              'category_id': 'work',
              'category_name': 'Work',
              'count': 5,
              'unread': 2,
              'color_hex': '#3B82F6',
            },
          ],
          'top_senders': [
            {
              'sender_name': 'GitHub',
              'sender_email': 'notifications@github.com',
              'count': 3,
            },
          ],
        },
        'suggested_actions': ['stats', 'classify', 'label'],
      };

      final msg = AssistantMessage.fromChatResponse(id: 'm1', json: json);

      expect(msg.intent, AssistantIntent.stats);
      expect(msg.actionType, 'stats');
      expect(msg.stats, isNotNull);
      expect(msg.stats!.totalEmails, 10);
      expect(msg.stats!.categories.length, 1);
      expect(msg.stats!.topSenders.first.senderName, 'GitHub');
      expect(msg.suggestedActions.length, 3);
    });

    test('AssistantMessage.fromChatResponse parses unsupported other intent correctly', () {
      final json = {
        'reply': 'VinaBuddy hiện chỉ hỗ trợ 3 tính năng...',
        'intent': 'other',
        'action_type': 'unsupported',
        'stats': null,
        'classification': null,
        'proposal': null,
        'suggested_actions': ['stats', 'classify', 'label'],
      };

      final msg = AssistantMessage.fromChatResponse(id: 'm2', json: json);

      expect(msg.intent, AssistantIntent.other);
      expect(msg.actionType, 'unsupported');
      expect(msg.stats, isNull);
      expect(msg.suggestedActions, contains('stats'));
      expect(msg.suggestedActions, contains('classify'));
      expect(msg.suggestedActions, contains('label'));
    });

    test('CleanupProposalData copyWith toggles isApplied state', () {
      const proposal = CleanupProposalData(
        ruleId: 'r1',
        ruleName: 'Newsletter Rule',
        targetLabel: 'Newsletters',
        matchedCount: 5,
        sampleSubjects: ['Weekly digest'],
        explanation: 'Labels 5 emails',
        isApplied: false,
      );

      final updated = proposal.copyWith(isApplied: true);
      expect(updated.isApplied, isTrue);
      expect(updated.targetLabel, 'Newsletters');
    });
  });
}

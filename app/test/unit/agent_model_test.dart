import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';

void main() {
  group('AgentDefinition & RecruitedAgent Model Tests', () {
    test('AgentDefinition can be instantiated and mapped correctly', () {
      const def = AgentDefinition(
        id: 'thay_cung',
        defaultName: 'Thầy Cúng',
        category: 'spiritual',
        description: 'Chuyên trách ngày rằm, mùng 1, văn khấn và lễ nghi',
        avatarSymbol: '🏮',
        personality: AgentPersonality(
          tone: 'Trang nghiêm, thành kính',
          style: 'playful_vietnamese_office_humor',
        ),
        capabilities: [
          AgentCapability(
            id: 'lunar_calendar',
            name: 'Nhắc ngày rằm, mùng 1',
            description: 'Tra cứu ngày sóc vọng',
            supportedIntents: ['lunar_day_inquiry'],
          ),
        ],
        limitations: ['Không can thiệp vào hộp thư email'],
        requiredPermissions: [],
      );

      expect(def.id, 'thay_cung');
      expect(def.defaultName, 'Thầy Cúng');
      expect(def.capabilities.length, 1);
      expect(def.isPlaceholder, false);
    });

    test('RecruitedAgent serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final recruited = RecruitedAgent(
        agentId: 'thay_cung',
        customDisplayName: 'Thầy Phong Thuỷ Công Ty',
        recruitedAt: now,
      );

      final json = recruited.toJson();
      expect(json['agentId'], 'thay_cung');
      expect(json['customDisplayName'], 'Thầy Phong Thuỷ Công Ty');

      final fromJson = RecruitedAgent.fromJson(json);
      expect(fromJson.agentId, recruited.agentId);
      expect(fromJson.customDisplayName, recruited.customDisplayName);
      expect(fromJson.isDismissed, false);
      expect(
        fromJson.recruitedAt.millisecondsSinceEpoch ~/ 1000,
        now.millisecondsSinceEpoch ~/ 1000,
      );

      final dismissed = recruited.copyWith(isDismissed: true, dismissedAt: now);
      expect(dismissed.isDismissed, true);
      expect(dismissed.dismissedAt, now);

      final dismissedJson = dismissed.toJson();
      expect(dismissedJson['isDismissed'], true);
      final fromDismissedJson = RecruitedAgent.fromJson(dismissedJson);
      expect(fromDismissedJson.isDismissed, true);
    });

    test('AgentHandoff serialization and deserialization', () {
      const handoff = AgentHandoff(
        matched: false,
        confidence: 0.95,
        handoffRequired: true,
        sourceAgentId: 'thay_cung',
        recommendedAgentId: 'thu_ky_email',
        reason: 'Hỏi về lọc email',
        userQuery: 'Lọc email Shopee',
      );

      final json = handoff.toJson();
      expect(json['handoffRequired'], true);
      expect(json['sourceAgentId'], 'thay_cung');
      expect(json['recommendedAgentId'], 'thu_ky_email');

      final fromJson = AgentHandoff.fromJson(json);
      expect(fromJson.handoffRequired, true);
      expect(fromJson.recommendedAgentId, 'thu_ky_email');
    });
  });
}

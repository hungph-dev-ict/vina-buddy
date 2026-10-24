import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/agents/thay_cung/thay_cung_data.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/agent_chat_screen.dart';
import 'package:smart_inbox_ai/services/api_service.dart';
import 'package:smart_inbox_ai/services/local_store_service.dart';

class FakeApiService extends ApiService {
  @override
  Future<Map<String, dynamic>> sendAssistantMessage({
    required String message,
    String locale = 'vi',
    String? sessionId,
    String? agentId,
  }) async {
    if (message.contains('Đoan Ngọ') || message.contains('đoan ngọ')) {
      return {
        'reply':
            '🔍 [AI Dev Monitor] Phân loại Intent:\n'
            '```json\n'
            '{\n'
            '  "intent": "vietnamese_traditional_holidays",\n'
            '  "scores": {\n'
            '    "lunar_day_reminder": 0.01,\n'
            '    "traditional_offerings_and_prayers": 0.02,\n'
            '    "vietnamese_traditional_holidays": 0.95,\n'
            '    "other": 0.02\n'
            '  }\n'
            '}\n'
            '```\n\n'
            'Dạ thưa Giám đốc! **Tết Đoan Ngọ** (hay còn gọi là Tết Giết sâu bọ, Tết Đoan Dương) '
            'diễn ra vào ngày **Mùng 5 tháng 5 Âm lịch** hàng năm ạ!\n\n'
            '🏮 **Ý nghĩa phong tục:**\n'
            'Thời điểm này chuyển sang giữa hè, khí dương cực thịnh, sâu bọ và các mầm bệnh dễ phát sinh.',
        'intent': 'other',
        'action_type': 'knowledge',
        'confidence': 0.95,
        'llm_provider': 'Thầy Cúng Knowledge Engine',
        'agent_id': 'thay_cung',
        'recommend_agent_id': null,
        'intent_scores': {
          'lunar_day_reminder': 0.01,
          'traditional_offerings_and_prayers': 0.02,
          'vietnamese_traditional_holidays': 0.95,
          'other': 0.02,
        },
        'suggested_actions': <String>[],
      };
    }

    return {
      'reply': 'Dạ Giám đốc cần em giúp gì ạ?',
      'intent': 'other',
      'action_type': 'knowledge',
      'confidence': 0.8,
      'llm_provider': 'Thầy Cúng Knowledge Engine',
      'agent_id': 'thay_cung',
      'recommend_agent_id': null,
      'intent_scores': {'other': 1.0},
      'suggested_actions': <String>[],
    };
  }
}

void main() {
  setUp(() {
    LocalStoreService().clearForTest();
  });

  testWidgets(
    'AgentChatScreen renders Thầy Cúng chat, answers Tết Đoan Ngọ accurately and displays capability header',
    (WidgetTester tester) async {
      final fakeApi = FakeApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
          child: const MaterialApp(
            home: AgentChatScreen(
              agent: thayCungAgentDefinition,
              customName: 'Thầy Cúng',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Verify header title and initial greeting
      expect(find.text('Thầy Cúng'), findsOneWidget);
      expect(
        find.textContaining(
          'Kính chào Giám đốc! Em là Thầy Cúng của công ty vnverse',
        ),
        findsOneWidget,
      );

      // Step 2: Input query about Tết Đoan Ngọ
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Tết Đoan Ngọ là ngày nào?');
      await tester.pump();

      // Step 3: Tap send button
      final sendBtnFinder = find.byIcon(Icons.send_rounded);
      expect(sendBtnFinder, findsOneWidget);
      await tester.tap(sendBtnFinder);
      await tester.pumpAndSettle();

      // Step 4: Verify user message is displayed in chat
      expect(find.text('Tết Đoan Ngọ là ngày nào?'), findsOneWidget);

      // Step 5: Verify Thầy Cúng answers with cultural holiday knowledge (NOT repeating opening greeting)
      expect(find.textContaining('Mùng 5 tháng 5 Âm lịch'), findsOneWidget);
      expect(find.textContaining('Tết Giết sâu bọ'), findsOneWidget);

      // Step 6: Verify AI Dev Monitor displays the correct capability intent
      expect(
        find.textContaining('vietnamese_traditional_holidays'),
        findsOneWidget,
      );
    },
  );
}

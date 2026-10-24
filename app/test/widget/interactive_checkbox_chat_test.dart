import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/agents/thay_cung/thay_cung_data.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/agent_chat_screen.dart';
import 'package:smart_inbox_ai/services/api_service.dart';

class FakeInteractiveChatApiService extends ApiService {
  String lastReceivedMessage = '';

  @override
  Future<Map<String, dynamic>> sendAssistantMessage({
    required String message,
    String locale = 'vi',
    String? sessionId,
    String? agentId,
  }) async {
    lastReceivedMessage = message;

    if (message.contains('nhắc') || message.contains('mùng 1')) {
      return {
        'reply': 'Thưa Giám đốc, Thầy Cúng có thể tự động nhắc nhở Giám đốc các ngày sóc vọng & rằm hàng tháng.',
        'intent': 'reminder',
        'action_type': 'reminder',
        'confidence': 0.98,
        'llm_provider': 'Test Provider',
        'interactive_config': {
          'config_type': 'reminder_quick_setup',
          'title': 'Chọn ngày nhắc sóc vọng & rằm:',
          'is_multi_select': true,
          'options': [
            {
              'id': 'mung_1',
              'label': 'Mùng 1 Âm lịch',
              'default_checked': true,
            },
            {
              'id': 'ngay_ram',
              'label': 'Ngày rằm (15) Âm lịch',
              'default_checked': true,
            },
          ],
          'confirm_label': 'Xác nhận lịch nhắc',
        },
      };
    }

    return {
      'reply': 'Dạ vâng, em đã ghi nhận yêu cầu của Giám đốc.',
      'intent': 'reminder',
      'action_type': 'text',
      'confidence': 0.95,
      'llm_provider': 'Test Provider',
    };
  }
}

void main() {
  testWidgets(
    'AgentChatScreen displays interactive checkboxes and confirms selection',
    (WidgetTester tester) async {
      final fakeApi = FakeInteractiveChatApiService();

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

      // Enter prompt: "Nhắc ngày mùng 1 & rằm"
      await tester.enterText(find.byType(TextField), 'Nhắc ngày mùng 1 & rằm');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Check that interactive checkboxes rendered
      expect(find.text('Chọn ngày nhắc sóc vọng & rằm:'), findsOneWidget);
      expect(find.text('Mùng 1 Âm lịch'), findsOneWidget);
      expect(find.text('Ngày rằm (15) Âm lịch'), findsOneWidget);
      expect(find.text('Xác nhận lịch nhắc'), findsOneWidget);

      // Verify checkboxes are present
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsNWidgets(2));

      // Tap "Xác nhận lịch nhắc" button
      await tester.tap(find.text('Xác nhận lịch nhắc'));
      await tester.pumpAndSettle();

      // Verify confirmed message was sent to backend
      expect(fakeApi.lastReceivedMessage, contains('Tôi chọn lịch nhắc'));
      expect(fakeApi.lastReceivedMessage, contains('Mùng 1 Âm lịch'));
      expect(fakeApi.lastReceivedMessage, contains('Ngày rằm (15) Âm lịch'));
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/agents/thay_cung/thay_cung_data.dart';
import 'package:smart_inbox_ai/models/reminder_model.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/widgets/agent_reminders_sheet.dart';
import 'package:smart_inbox_ai/services/api_service.dart';

class FakeRemindersApiService extends ApiService {
  List<AgentReminder> reminders = [
    AgentReminder(
      id: 'rem_01',
      agentId: 'thay_cung',
      title: 'Nhắc sóc vọng & rằm tháng này',
      description: 'Tự động nhắc thắp hương mùng 1 và ngày rằm',
      schedule: const ReminderSchedule(type: 'lunar_monthly', days: [1, 15]),
      targetTime: '07:00',
      isEnabled: true,
      createdAt: DateTime(2026, 10, 24),
    ),
  ];

  @override
  Future<List<AgentReminder>> getAgentReminders(String agentId) async {
    return List.from(reminders);
  }

  @override
  Future<AgentReminder> updateAgentReminder(
    String reminderId, {
    bool? isEnabled,
    String? targetTime,
    String? occasion,
  }) async {
    final idx = reminders.indexWhere((r) => r.id == reminderId);
    if (idx != -1) {
      reminders[idx] = reminders[idx].copyWith(
        isEnabled: isEnabled ?? reminders[idx].isEnabled,
        targetTime: targetTime ?? reminders[idx].targetTime,
        occasion: occasion ?? reminders[idx].occasion,
      );
      return reminders[idx];
    }
    throw ApiException(statusCode: 404, message: 'Not found');
  }

  @override
  Future<Map<String, dynamic>> testRunAgentReminder(String reminderId) async {
    return {
      'message': 'Đã gửi thông báo kiểm tra!',
      'test_output': 'Kính chào Giám đốc! Hôm nay là ngày sóc vọng...',
    };
  }

  @override
  Future<void> deleteAgentReminder(String reminderId) async {
    reminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<AgentReminder> createAgentReminder(
    String agentId,
    Map<String, dynamic> data,
  ) async {
    final newRem = AgentReminder.fromJson({
      ...data,
      'id': 'rem_new_${DateTime.now().millisecondsSinceEpoch}',
      'agent_id': agentId,
      'created_at': DateTime.now().toIso8601String(),
    });
    reminders.add(newRem);
    return newRem;
  }
}

void main() {
  testWidgets(
    'AgentRemindersSheet renders reminder and allows toggle and test run',
    (WidgetTester tester) async {
      final fakeApi = FakeRemindersApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
          child: MaterialApp(
            home: Scaffold(
              body: AgentRemindersSheet(agent: thayCungAgentDefinition),
            ),
          ),
        ),
      );

      // Initial load pump
      await tester.pumpAndSettle();

      // Verify header and autonomous banner
      expect(find.text('Lịch nhắc nhở • Thầy Cúng'), findsOneWidget);
      expect(find.text('Tác vụ chạy ngầm tự chủ 24/24'), findsOneWidget);
      expect(find.text('Nhắc sóc vọng & rằm tháng này'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);

      // Test toggle switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(fakeApi.reminders.first.isEnabled, false);

      // Test run button
      final testRunFinder = find.text('Chạy thử ngay');
      expect(testRunFinder, findsOneWidget);
      await tester.tap(testRunFinder);
      await tester.pumpAndSettle();
      expect(find.text('Đã gửi thông báo kiểm tra!'), findsOneWidget);
    },
  );
}

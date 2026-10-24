import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/services/local_store_service.dart';

void main() {
  group('LocalStoreService Unit Tests', () {
    late LocalStoreService service;
    late Directory tempDir;
    late File testStoreFile;

    setUp(() async {
      service = LocalStoreService();
      service.clearForTest();
      tempDir = await Directory.systemTemp.createTemp('vnverse_test_');
      testStoreFile = File('${tempDir.path}/test_store.json');
      await service.init(customFile: testStoreFile);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Initializes with default assistant name and onboarded false', () {
      expect(service.assistantName, 'Trợ lý Giám đốc');
      expect(service.isOnboarded, false);
      expect(service.recruitedAgents, isEmpty);
    });

    test('Persists updated assistant name and marks onboarded true', () async {
      await service.setAssistantName('Jarvis Giám Đốc');
      expect(service.assistantName, 'Jarvis Giám Đốc');
      expect(service.isOnboarded, true);

      // Verify file persistence
      expect(await testStoreFile.exists(), true);
      final newService = LocalStoreService();
      await newService.init(customFile: testStoreFile);
      expect(newService.assistantName, 'Jarvis Giám Đốc');
      expect(newService.isOnboarded, true);
    });

    test(
      'Recruits agent, prevents duplicate recruitment, and allows renaming',
      () async {
        final success = await service.recruitAgent('thay_cung', 'Thầy Cúng');
        expect(success, true);
        expect(service.isAgentRecruited('thay_cung'), true);

        // Duplicate recruitment rejected
        final duplicate = await service.recruitAgent('thay_cung', 'Thầy Cúng');
        expect(duplicate, false);

        // Rename agent
        final renameSuccess = await service.renameRecruitedAgent(
          'thay_cung',
          'Thầy Phong Thuỷ',
        );
        expect(renameSuccess, true);
        expect(
          service.getRecruitedAgent('thay_cung')?.customDisplayName,
          'Thầy Phong Thuỷ',
        );
      },
    );

    test('Saves and retrieves agent chat history', () async {
      final messages = [
        {'id': '1', 'text': 'Xin chào', 'role': 'user'},
        {'id': '2', 'text': 'Chào Giám đốc', 'role': 'assistant'},
      ];

      await service.saveChatHistory('thay_cung', messages);
      final retrieved = service.getChatHistory('thay_cung');
      expect(retrieved.length, 2);
      expect(retrieved[0]['text'], 'Xin chào');
    });

    test(
      'Dismisses agent, retains chat history, and allows re-recruiting',
      () async {
        await service.recruitAgent('thay_cung', 'Thầy Cúng');
        expect(service.isAgentRecruited('thay_cung'), true);
        expect(service.isAgentDismissed('thay_cung'), false);

        // Save messages before dismissal
        await service.saveChatHistory('thay_cung', [
          {'id': 'm1', 'text': 'Lịch làm lễ', 'role': 'user'},
        ]);

        // Dismiss
        final dismissOk = await service.dismissAgent('thay_cung');
        expect(dismissOk, true);
        expect(service.isAgentDismissed('thay_cung'), true);
        expect(service.isAgentRecruited('thay_cung'), false);

        // History is retained
        final history = service.getChatHistory('thay_cung');
        expect(history.length, 1);
        expect(history.first['text'], 'Lịch làm lễ');

        // Re-recruiting reactivates the employee
        final reactivated = await service.recruitAgent(
          'thay_cung',
          'Thầy Cúng Đệ Nhất',
        );
        expect(reactivated, true);
        expect(service.isAgentRecruited('thay_cung'), true);
        expect(service.isAgentDismissed('thay_cung'), false);
        expect(
          service.getRecruitedAgent('thay_cung')?.customDisplayName,
          'Thầy Cúng Đệ Nhất',
        );
      },
    );
  });
}

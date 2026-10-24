import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/chat_assistant_screen.dart';
import 'package:smart_inbox_ai/services/api_service.dart';
import 'package:smart_inbox_ai/services/local_store_service.dart';

class FakeCoordinatorApiService extends ApiService {
  @override
  Future<Map<String, dynamic>> sendAssistantMessage({
    required String message,
    String locale = 'vi',
    String? sessionId,
    String? agentId,
  }) async {
    final lower = message.toLowerCase();

    // 1. Out of scope: Politics & Ethics
    if (lower.contains('chính trị') || lower.contains('đạo đức')) {
      return {
        'reply':
            '🔍 [AI Dev Monitor] Phân loại Intent:\n'
            '```json\n'
            '{\n'
            '  "intent": "out_of_scope",\n'
            '  "scores": {\n'
            '    "recommend_agent": 0.02,\n'
            '    "chitchat": 0.02,\n'
            '    "out_of_scope": 0.96\n'
            '  }\n'
            '}\n'
            '```\n\n'
            'Thưa Giám đốc, em là Trợ lý văn phòng vnverse. Em xin phép từ chối thảo luận các vấn đề liên quan tới chính trị, đạo đức hoặc các chủ đề nhạy cảm này ạ. Em luôn sẵn sàng hỗ trợ sếp kết nối nhân sự và quản lý công việc văn phòng!',
        'intent': 'out_of_scope',
        'action_type': 'unsupported',
        'confidence': 0.98,
        'llm_provider': 'Safety Guardrail',
        'agent_id': 'coordinator',
        'recommend_agent_id': null,
        'intent_scores': {
          'recommend_agent': 0.02,
          'chitchat': 0.02,
          'out_of_scope': 0.96,
        },
        'suggested_actions': <String>[],
      };
    }

    // 2. Recommend agent: Find specific skill (e.g. Cúng rằm -> Thầy Cúng)
    if (lower.contains('cúng') ||
        lower.contains('thầy cúng') ||
        lower.contains('rằm')) {
      return {
        'reply':
            '🔍 [AI Dev Monitor] Phân loại Intent:\n'
            '```json\n'
            '{\n'
            '  "intent": "recommend_agent",\n'
            '  "scores": {\n'
            '    "recommend_agent": 0.95,\n'
            '    "chitchat": 0.03,\n'
            '    "out_of_scope": 0.02\n'
            '  }\n'
            '}\n'
            '```\n\n'
            'Thưa Giám đốc! Việc này thuộc chuyên môn của **Thầy Cúng** (Chuyên gia văn hoá tâm linh công sở) đấy ạ!\n\n'
            'Sếp có thể qua mục **Nhân viên** để giao việc trực tiếp, hoặc ghé qua **Chợ tuyển dụng** để chiêu mộ nhân sự này về công ty nhé!',
        'intent': 'recommend_agent',
        'action_type': 'recommend_agent',
        'confidence': 0.95,
        'llm_provider': 'Coordinator Registry Search',
        'agent_id': 'coordinator',
        'recommend_agent_id': 'thay_cung',
        'intent_scores': {
          'recommend_agent': 0.95,
          'chitchat': 0.03,
          'out_of_scope': 0.02,
        },
        'suggested_actions': <String>[],
      };
    }

    // 3. Recommend agent: Market Overview
    if (lower.contains('chợ tuyển dụng') || lower.contains('nhân sự')) {
      return {
        'reply':
            '🔍 [AI Dev Monitor] Phân loại Intent:\n'
            '```json\n'
            '{\n'
            '  "intent": "recommend_agent",\n'
            '  "scores": {\n'
            '    "recommend_agent": 0.95,\n'
            '    "chitchat": 0.03,\n'
            '    "out_of_scope": 0.02\n'
            '  }\n'
            '}\n'
            '```\n\n'
            'Dạ thưa Giám đốc! Hiện tại trên **Chợ tuyển dụng** vnverse đang có các nhân sự sáng giá sẵn sàng đầu quân cho sếp:\n\n'
            '• 🏮 **Thầy Cúng**: Chuyên gia tâm linh công sở\n'
            '• 💰 **Kế toán Chi tiêu**: Quản lý ngân sách công ty\n'
            '• 💻 **IT Helpdesk**: Hỗ trợ kỹ thuật máy tính\n'
            '• 📧 **Thư ký Email**: Dọn dẹp hòm thư Gmail\n\n'
            'Sếp muốn chiêu mộ ai có thể qua tab **Chợ tuyển dụng** để bấm tuyển ngay nhé!',
        'intent': 'recommend_agent',
        'action_type': 'recommend_agent',
        'confidence': 0.95,
        'llm_provider': 'Coordinator Market Directory',
        'agent_id': 'coordinator',
        'recommend_agent_id': null,
        'intent_scores': {
          'recommend_agent': 0.95,
          'chitchat': 0.03,
          'out_of_scope': 0.02,
        },
        'suggested_actions': <String>[],
      };
    }

    // 4. Chitchat (Free form)
    return {
      'reply':
          '🔍 [AI Dev Monitor] Phân loại Intent:\n'
          '```json\n'
          '{\n'
          '  "intent": "chitchat",\n'
          '  "scores": {\n'
          '    "recommend_agent": 0.05,\n'
          '    "chitchat": 0.92,\n'
          '    "out_of_scope": 0.03\n'
          '  }\n'
          '}\n'
          '```\n\n'
          'Chào sếp! Em là Trợ lý của sếp tại vnverse. Dù không có lương và bảo hiểm nhưng em luôn tràn đầy năng lượng để phục vụ Giám đốc. Hôm nay sếp cần em hỗ trợ việc gì ạ?',
      'intent': 'chitchat',
      'action_type': 'chitchat',
      'confidence': 0.92,
      'llm_provider': 'Coordinator Persona Engine',
      'agent_id': 'coordinator',
      'recommend_agent_id': null,
      'intent_scores': {
        'recommend_agent': 0.05,
        'chitchat': 0.92,
        'out_of_scope': 0.03,
      },
      'suggested_actions': <String>[],
    };
  }
}

class FakeIsOnboardedNotifier extends IsOnboardedNotifier {
  @override
  bool build() => true;
}

Widget createTestWidget(FakeCoordinatorApiService api) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(api),
      isOnboardedProvider.overrideWith(FakeIsOnboardedNotifier.new),
      chatAssistantProvider.overrideWith(ChatAssistantNotifier.new),
    ],
    child: const MaterialApp(home: ChatAssistantScreen()),
  );
}

void main() {
  setUp(() {
    LocalStoreService().clearForTest();
  });

  group('ChatAssistantScreen Widget Tests', () {
    testWidgets(
      'Initial render displays welcome message, shortcuts bar, and input text field',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        // 1. Verify app bar title and subtitle
        expect(find.text('Trợ lý Giám đốc • vnverse'), findsOneWidget);

        // 2. Verify initial welcome message from assistant
        expect(
          find.textContaining('Chào Giám đốc! Cuối cùng sếp cũng đến công ty'),
          findsOneWidget,
        );

        // 3. Verify prominent shortcut action buttons
        expect(find.text('Chợ tuyển dụng 🎪'), findsOneWidget);
        expect(find.text('Tra cứu ngày cúng 🏮'), findsOneWidget);
        expect(find.text('Danh sách nhân sự 👥'), findsOneWidget);

        // 4. Verify chat input field and send button
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'User can search for skills and Assistant recommends agent with Recruitment Card',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        // Step 1: Input text searching for employee
        final textField = find.byType(TextField);
        await tester.enterText(
          textField,
          'Tìm cho tôi nhân viên biết cúng rằm',
        );
        await tester.pump();

        // Step 2: Tap send button
        final sendBtn = find.byIcon(Icons.send_rounded);
        await tester.tap(sendBtn);
        await tester.pumpAndSettle();

        // Step 3: Verify user message is rendered
        expect(
          find.text('Tìm cho tôi nhân viên biết cúng rằm'),
          findsOneWidget,
        );

        // Step 4: Verify Assistant response with recommend_agent intent
        expect(
          find.textContaining('Việc này thuộc chuyên môn của **Thầy Cúng**'),
          findsOneWidget,
        );
        expect(find.textContaining('recommend_agent'), findsOneWidget);

        // Step 5: Verify the rich RecommendationCard with recruit action button is displayed
        expect(find.text('Đề xuất tuyển dụng: Thầy Cúng'), findsOneWidget);
        expect(find.text('Tuyển dụng ngay'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping top shortcut sends prompt and renders market overview',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        // Tap "Chợ tuyển dụng 🎪" shortcut
        final marketShortcut = find.text('Chợ tuyển dụng 🎪');
        expect(marketShortcut, findsOneWidget);
        await tester.tap(marketShortcut);
        await tester.pumpAndSettle();

        // Verify sent prompt and response
        expect(
          find.text('Giới thiệu các nhân sự hiện có trên Chợ tuyển dụng'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Hiện tại trên **Chợ tuyển dụng** vnverse đang có các nhân sự sáng giá',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Chitchat intent: Assistant replies freely with warm coordinator persona',
      (WidgetTester tester) async {
        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Chào em, hôm nay có khỏe không?');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Chào em, hôm nay có khỏe không?'), findsOneWidget);
        expect(
          find.textContaining(
            'Dù không có lương và bảo hiểm nhưng em luôn tràn đầy năng lượng',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('chitchat'), findsOneWidget);
      },
    );

    testWidgets(
      'Out of scope intent: Assistant politely declines political and ethical topics',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Bàn luận về chính trị và bầu cử');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Bàn luận về chính trị và bầu cử'), findsOneWidget);
        expect(
          find.textContaining(
            'từ chối thảo luận các vấn đề liên quan tới chính trị, đạo đức',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('out_of_scope'), findsOneWidget);
      },
    );

    testWidgets(
      'Empty text input does not send message when tapping send button',
      (WidgetTester tester) async {
        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        final initialCount = find.byType(ListView).evaluate().length;

        // Tap send button without typing
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(ListView).evaluate().length, initialCount);
      },
    );

    testWidgets(
      'Can recruit recommended agent directly from RecommendationCard',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeApi = FakeCoordinatorApiService();

        await tester.pumpWidget(createTestWidget(fakeApi));
        await tester.pumpAndSettle();

        // Trigger agent recommendation
        await tester.enterText(find.byType(TextField), 'Tìm người cúng rằm');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        // Verify "Tuyển dụng ngay" button is visible and tap it
        final recruitBtn = find.text('Tuyển dụng ngay');
        expect(recruitBtn, findsOneWidget);
        await tester.tap(recruitBtn);
        await tester.pumpAndSettle();

        // Button changes to "Đã vào công ty"
        expect(find.text('Đã vào công ty'), findsOneWidget);
      },
    );
  });
}

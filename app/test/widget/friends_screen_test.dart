import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';
import 'package:smart_inbox_ai/screens/agent_chat_screen.dart';
import 'package:smart_inbox_ai/screens/friends_screen.dart';
import 'package:smart_inbox_ai/services/local_store_service.dart';

void main() {
  setUp(() {
    LocalStoreService().clearForTest();
  });

  testWidgets(
    'FriendsScreen lists active employees and allows dismissing them',
    (WidgetTester tester) async {
      final store = LocalStoreService();
      await store.recruitAgent('thay_cung', 'Thầy Cúng');

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FriendsScreen())),
      );
      await tester.pumpAndSettle();

      // Verify header and employee presence
      expect(find.text('Nhân viên của tôi'), findsOneWidget);
      expect(find.text('Thầy Cúng'), findsOneWidget);
      expect(find.text('Đang làm việc'), findsOneWidget);

      // Open popup menu on employee card
      final moreBtn = find.byIcon(Icons.more_vert_rounded);
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Tap "Sa thải nhân viên"
      expect(find.text('Sa thải nhân viên'), findsOneWidget);
      await tester.tap(find.text('Sa thải nhân viên'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Sa thải nhân viên?'), findsOneWidget);
      expect(find.text('Xác nhận sa thải'), findsOneWidget);

      // Confirm dismissal
      await tester.tap(find.text('Xác nhận sa thải'));
      await tester.pumpAndSettle();

      // Since _showDismissed toggle is initially false, Thầy Cúng is hidden
      expect(
        find.textContaining('Không có nhân viên nào đang làm việc'),
        findsOneWidget,
      );

      // Toggle switch to show dismissed employees
      final toggleSwitch = find.byType(Switch);
      expect(toggleSwitch, findsOneWidget);
      await tester.tap(toggleSwitch);
      await tester.pumpAndSettle();

      // Thầy Cúng reappears with "Đã sa thải" badge
      expect(find.text('Thầy Cúng'), findsOneWidget);
      expect(find.text('Đã sa thải'), findsOneWidget);
    },
  );

  testWidgets(
    'FriendsScreen renders correctly without null exception when legacy RecruitedAgent has null isDismissed',
    (WidgetTester tester) async {
      // Simulate legacy JSON where isDismissed was missing/null
      final legacyJson = {
        'agentId': 'thay_cung',
        'customDisplayName': 'Thầy Cúng Cũ',
        'recruitedAt': DateTime.now().toIso8601String(),
        // 'isDismissed' intentionally omitted
      };

      final legacyAgent = RecruitedAgent.fromJson(legacyJson);
      expect(legacyAgent.isDismissed, isFalse);

      final store = LocalStoreService();
      await store.recruitAgent(
        legacyAgent.agentId,
        legacyAgent.customDisplayName,
      );

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FriendsScreen())),
      );
      await tester.pumpAndSettle();

      // Must render smoothly without throwing 'type Null is not a subtype of bool'
      expect(find.text('Nhân viên của tôi'), findsOneWidget);
      expect(find.text('Thầy Cúng Cũ'), findsOneWidget);
      expect(find.text('Đang làm việc'), findsOneWidget);
    },
  );

  testWidgets(
    'FriendsScreen displays empty state when no employees and invokes onNavigateToMarket',
    (WidgetTester tester) async {
      bool marketNavigated = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FriendsScreen(
              onNavigateToMarket: () {
                marketNavigated = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Công ty chưa có nhân viên nào!'), findsOneWidget);
      final ctaButton = find.text('Khám phá Chợ tuyển dụng 🚀');
      expect(ctaButton, findsOneWidget);

      await tester.tap(ctaButton);
      await tester.pump();

      expect(marketNavigated, isTrue);
    },
  );

  testWidgets('FriendsScreen allows renaming an employee via NamingDialog', (
    WidgetTester tester,
  ) async {
    final store = LocalStoreService();
    await store.recruitAgent('thay_cung', 'Thầy Cúng');

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FriendsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thầy Cúng'), findsOneWidget);

    // Open popup menu
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Tap "Đổi tên nhân viên"
    expect(find.text('Đổi tên nhân viên'), findsOneWidget);
    await tester.tap(find.text('Đổi tên nhân viên'));
    await tester.pumpAndSettle();

    // Dialog opens
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Thầy Phong Thuỷ VIP');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    // Verify renamed
    expect(find.text('Thầy Phong Thuỷ VIP'), findsOneWidget);
  });

  testWidgets(
    'AgentChatScreen displays dismissed banner and hides input bar when agent is dismissed',
    (WidgetTester tester) async {
      final store = LocalStoreService();
      await store.recruitAgent('thay_cung', 'Thầy Cúng');
      await store.dismissAgent('thay_cung');

      const agentDef = AgentDefinition(
        id: 'thay_cung',
        defaultName: 'Thầy Cúng',
        category: 'spiritual',
        description: 'Văn khấn và lễ nghi',
        avatarSymbol: '🏮',
        personality: AgentPersonality(tone: 'Trang nghiêm', style: 'office'),
        capabilities: [],
        limitations: [],
        requiredPermissions: [],
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AgentChatScreen(agent: agentDef, customName: 'Thầy Cúng'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar status
      expect(find.text('Đã sa thải • Xem lại lịch sử'), findsOneWidget);

      // Verify read-only banner is displayed
      expect(
        find.text(
          'Nhân viên này đã bị sa thải. Giám đốc chỉ có thể xem lại lịch sử trò chuyện.',
        ),
        findsOneWidget,
      );

      // Verify send button is not present
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    },
  );
}

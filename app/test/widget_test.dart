import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/main.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/main_navigation_screen.dart';

void main() {
  testWidgets(
    'SmartInboxApp renders onboarding screen on first launch in English',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SmartInboxApp()));
      await tester.pumpAndSettle();

      // Verify app title and connection buttons are present in English
      expect(find.text('vnverse'), findsOneWidget);
      expect(find.text('Connect Gmail (Google OAuth)'), findsOneWidget);
      expect(find.text('Continue in Dev/Sandbox Mode'), findsOneWidget);
      expect(find.text('Chủ quyền Giám đốc'), findsOneWidget);
      expect(find.text('Bảo mật & Riêng tư'), findsOneWidget);
      expect(find.text('Chiêu mộ nhân tài'), findsOneWidget);
    },
  );

  testWidgets('SmartInboxApp dynamically switches language to Vietnamese', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartInboxApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Initially in English
    expect(find.text('Connect Gmail (Google OAuth)'), findsOneWidget);

    // Switch locale to Vietnamese
    container.read(localeProvider.notifier).setLocale(const Locale('vi'));
    await tester.pumpAndSettle();

    // Verify Vietnamese translations
    expect(find.text('Kết nối Gmail (Google OAuth)'), findsOneWidget);
    expect(find.text('Tiếp tục ở chế độ Thử nghiệm / Sandbox'), findsOneWidget);
  });

  testWidgets(
    'SmartInboxApp transitions to MainNavigationScreen when authenticated',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SmartInboxApp(),
        ),
      );
      await tester.pumpAndSettle();

      container
          .read(authProvider.notifier)
          .setAuthenticated(
            email: 'tester@gmail.com',
            sessionToken: 'test_token',
          );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Verify Tab 0 shows default assistant name and Tab 1 shows "Nhân viên"
      expect(find.text('Trợ lý Giám đốc'), findsWidgets);
      expect(find.text('Nhân viên'), findsWidgets);

      // Custom assistant name updates Tab 0
      await container.read(coordinatorNameProvider.notifier).setName('Tèo');
      await tester.pumpAndSettle();
      expect(find.text('Tèo'), findsWidgets);
    },
  );
}

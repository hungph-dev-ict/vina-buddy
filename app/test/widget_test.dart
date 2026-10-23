import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/main.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';

void main() {
  testWidgets('SmartInboxApp renders onboarding screen on first launch in English',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartInboxApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app title and connection buttons are present in English
    expect(find.text('Smart Inbox AI'), findsOneWidget);
    expect(find.text('Connect Gmail (Google OAuth)'), findsOneWidget);
    expect(find.text('Continue in Dev/Sandbox Mode'), findsOneWidget);
    expect(find.text('Zero Permanent Storage'), findsOneWidget);
    expect(find.text('Labels Only'), findsOneWidget);
    expect(find.text('Explicit Approval'), findsOneWidget);
  });

  testWidgets('SmartInboxApp dynamically switches language to Vietnamese',
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

    // Initially in English
    expect(find.text('Connect Gmail (Google OAuth)'), findsOneWidget);

    // Switch locale to Vietnamese
    container.read(localeProvider.notifier).setLocale(const Locale('vi'));
    await tester.pumpAndSettle();

    // Verify Vietnamese translations
    expect(find.text('Kết nối Gmail (Google OAuth)'), findsOneWidget);
    expect(find.text('Tiếp tục ở chế độ Thử nghiệm / Sandbox'), findsOneWidget);
    expect(find.text('Không lưu trữ vĩnh viễn'), findsOneWidget);
    expect(find.text('Chỉ thao tác gắn nhãn'), findsOneWidget);
    expect(find.text('Cần bạn phê duyệt'), findsOneWidget);
  });
}

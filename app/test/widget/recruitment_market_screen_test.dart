import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/screens/recruitment_market_screen.dart';
import 'package:smart_inbox_ai/services/local_store_service.dart';

void main() {
  setUp(() {
    LocalStoreService().clearForTest();
  });

  testWidgets(
    'RecruitmentMarketScreen renders agents catalog and enables hiring Thầy Cúng',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RecruitmentMarketScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Market Title & Banner
      expect(find.text('Chợ tuyển dụng'), findsOneWidget);
      expect(find.text('Sàn Nhân Tài vnverse'), findsOneWidget);

      // Verify Thầy Cúng is listed with Xem hồ sơ and Tuyển dụng button
      expect(find.text('Thầy Cúng'), findsOneWidget);
      expect(find.text('Xem hồ sơ'), findsWidgets);
      expect(find.text('Tuyển dụng ngay'), findsOneWidget);

      // Verify placeholder agents are listed as Sắp mở tuyển
      expect(find.text('Thư ký Email'), findsOneWidget);
      expect(find.text('Sắp mở tuyển'), findsWidgets);

      // Tap on Xem hồ sơ for Thầy Cúng to view capabilities sheet
      await tester.tap(find.text('Xem hồ sơ').first);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with Thầy Cúng details
      expect(find.text('✅ Có thể làm gì:'), findsOneWidget);
      expect(
        find.text('❌ Không thể làm gì (Giới hạn năng lực):'),
        findsOneWidget,
      );

      // Scroll down to reveal recruitment CTA button in bottom sheet
      final recruitCta = find.text('Tuyển dụng nhân viên này');
      await tester.scrollUntilVisible(
        recruitCta,
        200.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(recruitCta, findsOneWidget);

      // Tap to recruit
      await tester.tap(recruitCta);
      await tester.pumpAndSettle();

      // Verify recruitment success dialog appears
      expect(find.text('Tuyển dụng thành công!'), findsOneWidget);
      expect(find.text('Tuyệt vời!'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Tuyệt vời!'));
      await tester.pumpAndSettle();

      // Verify Thầy Cúng is now removed from the market list
      expect(find.text('Tuyển dụng ngay'), findsNothing);
    },
  );

  testWidgets(
    'RecruitmentMarketScreen shows celebration empty state when all agents are recruited',
    (WidgetTester tester) async {
      // Mark all agents as recruited in local store
      await LocalStoreService().recruitAgent('thay_cung', 'Thầy Cúng');
      await LocalStoreService().recruitAgent('thu_ky_email', 'Thư ký Email');
      await LocalStoreService().recruitAgent('ke_toan_chi_tieu', 'Kế toán');
      await LocalStoreService().recruitAgent('it_support', 'IT');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RecruitmentMarketScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Đã chiêu mộ toàn bộ nhân sự!'), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);
    },
  );
}

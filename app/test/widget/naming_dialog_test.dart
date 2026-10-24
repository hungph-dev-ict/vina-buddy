import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/screens/widgets/naming_dialog.dart';

void main() {
  testWidgets(
    'NamingDialog renders title, prefilled text, and validates empty input',
    (WidgetTester tester) async {
      String? submittedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  submittedName = await NamingDialog.show(
                    context,
                    title: 'Đặt tên Trợ lý',
                    currentName: 'Trợ lý Giám đốc',
                    subtitle: 'Đặt tên riêng cho trợ lý',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Đặt tên Trợ lý'), findsOneWidget);
      expect(find.text('Đặt tên riêng cho trợ lý'), findsOneWidget);
      expect(find.text('Trợ lý Giám đốc'), findsOneWidget);

      // Enter empty text and submit
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Tên không được để trống'), findsOneWidget);

      // Enter valid new name and submit
      await tester.enterText(find.byType(TextField), 'Alice Thư Ký');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and returned value
      expect(find.byType(NamingDialog), findsNothing);
      expect(submittedName, 'Alice Thư Ký');
    },
  );
}

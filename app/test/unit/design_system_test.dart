import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';
import 'package:smart_inbox_ai/theme/app_theme.dart';
import 'package:smart_inbox_ai/widgets/app_badge.dart';
import 'package:smart_inbox_ai/widgets/app_button.dart';
import 'package:smart_inbox_ai/widgets/email_card.dart';
import 'package:smart_inbox_ai/widgets/empty_state_view.dart';
import 'package:smart_inbox_ai/widgets/rule_card.dart';
import 'package:smart_inbox_ai/widgets/status_banner.dart';

void main() {
  group('Design System Widgets', () {
    testWidgets('AppBadge renders various variants correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                AppBadge(label: 'Neutral Tag'),
                AppBadge(
                  label: 'Newsletters',
                  variant: AppBadgeVariant.addLabel,
                ),
                AppBadge(label: 'Spam', variant: AppBadgeVariant.removeLabel),
                AppBadge(
                  label: '85%',
                  variant: AppBadgeVariant.aiConfidence,
                  confidence: 0.85,
                ),
                AppBadge(label: 'Ollama', variant: AppBadgeVariant.aiProvider),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Neutral Tag'), findsOneWidget);
      expect(find.text('Newsletters'), findsOneWidget);
      expect(find.text('Spam'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Ollama'), findsOneWidget);
    });

    testWidgets('AppButton renders label and handles callbacks', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton.primary(
              label: 'Test Action',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Action'), findsOneWidget);
      await tester.tap(find.text('Test Action'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AppButton displays loading spinner when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton.primary(
              label: 'Loading Action',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('StatusBanner renders message and action label', (
      tester,
    ) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatusBanner.error(
              message: 'Network connection failed',
              actionLabel: 'Retry',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(actionTapped, isTrue);
    });

    testWidgets('EmptyStateView renders icon, texts, and CTA button', (
      tester,
    ) async {
      bool ctaTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox,
              title: 'Empty Inbox',
              subtitle: 'No messages to display right now.',
              buttonLabel: 'Sync Now',
              onButtonPressed: () => ctaTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty Inbox'), findsOneWidget);
      expect(find.text('No messages to display right now.'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      await tester.tap(find.text('Sync Now'));
      await tester.pump();
      expect(ctaTapped, isTrue);
    });

    testWidgets('EmailCard renders email information and labels', (
      tester,
    ) async {
      const email = EmailItem(
        id: 'msg_1',
        threadId: 'th_1',
        fromName: 'GitHub Updates',
        fromEmail: 'notifications@github.com',
        subject: 'Security Alert on Repository',
        snippet:
            'A new dependency vulnerability was detected in your repository.',
        date: '2026-10-23T10:00:00Z',
        labels: ['INBOX', 'Security'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: EmailCard(email: email)),
        ),
      );

      expect(find.text('GitHub Updates'), findsOneWidget);
      expect(find.text('notifications@github.com'), findsOneWidget);
      expect(find.text('Security Alert on Repository'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('RuleCard renders rule name and triggers toggle', (
      tester,
    ) async {
      bool toggled = false;
      const rule = RuleModel(
        id: 'rule_1',
        name: 'Auto-Label Invoices',
        naturalLanguage: 'Move receipts and invoices to Finance label',
        conditions: [
          RuleConditionModel(
            field: 'subject',
            operator: 'contains',
            value: 'invoice',
          ),
        ],
        actions: [RuleActionModel(type: 'add_label', label: 'Finance')],
        priority: 1,
        enabled: true,
        llmProvider: 'Ollama',
        llmConfidence: 0.95,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RuleCard(rule: rule, onToggle: (val) => toggled = val),
          ),
        ),
      );

      expect(find.text('Auto-Label Invoices'), findsOneWidget);
      expect(
        find.text('"Move receipts and invoices to Finance label"'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(toggled, isFalse);
    });

    testWidgets(
      'EmailCard renders Apple HIG styling with unread dot and chevron on iOS',
      (tester) async {
        const email = EmailItem(
          id: 'msg_ios',
          threadId: 'th_ios',
          fromName: 'Apple Developer',
          fromEmail: 'news@apple.com',
          subject: 'WWDC Highlights',
          snippet: 'Catch up on session videos and developer tools.',
          date: '2026-10-23T10:00:00Z',
          labels: ['INBOX', 'UNREAD'],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: EmailCard(email: email, isIosOverride: true),
            ),
          ),
        );

        expect(find.text('Apple Developer'), findsOneWidget);
        expect(find.text('WWDC Highlights'), findsOneWidget);
        expect(find.byType(CupertinoButton), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/screens/inbox_screen.dart';
import 'package:smart_inbox_ai/screens/rule_builder_screen.dart';
import 'package:smart_inbox_ai/screens/rules_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final screens = [
      const InboxScreen(),
      const RuleBuilderScreen(),
      RulesScreen(
        onNavigateToBuilder: () {
          setState(() => _currentIndex = 1);
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.mail_outline_rounded),
            selectedIcon: const Icon(Icons.mark_email_read_rounded),
            label: l10n?.navInbox ?? 'Inbox',
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: l10n?.navBuildRule ?? 'Build Rule',
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            selectedIcon: const Icon(Icons.rule_folder_rounded),
            label: l10n?.navMyRules ?? 'My Rules',
          ),
        ],
      ),
    );
  }
}

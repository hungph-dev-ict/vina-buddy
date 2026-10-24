import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/screens/chat_assistant_screen.dart';
import 'package:smart_inbox_ai/screens/friends_screen.dart';
import 'package:smart_inbox_ai/screens/personal_screen.dart';
import 'package:smart_inbox_ai/screens/recruitment_market_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platformOverride = ref.watch(platformOverrideProvider);
    final effectivePlatform = platformOverride ?? Theme.of(context).platform;
    final isIos = effectivePlatform == TargetPlatform.iOS;
    final assistantName = ref.watch(coordinatorNameProvider);

    final screens = [
      const ChatAssistantScreen(),
      FriendsScreen(
        onNavigateToMarket: () {
          setState(() => _currentIndex = 2);
        },
      ),
      const RecruitmentMarketScreen(),
      const PersonalScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: isIos
          ? _buildCupertinoBottomBar(context, isDark, l10n, assistantName)
          : _buildMaterialBottomBar(context, l10n, assistantName),
    );
  }

  Widget _buildCupertinoBottomBar(
    BuildContext context,
    bool isDark,
    AppLocalizations? l10n,
    String assistantName,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        backgroundColor: isDark
            ? const Color(0xEB1C1C1E)
            : const Color(0xF2F9F9F9),
        activeColor: const Color(0xFF6366F1),
        inactiveColor: isDark
            ? const Color(0xFF8E8E93)
            : const Color(0xFF999999),
        iconSize: 24,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chat_bubble_2),
            activeIcon: const Icon(CupertinoIcons.chat_bubble_2_fill),
            label: assistantName,
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Nhân viên',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bag),
            activeIcon: Icon(CupertinoIcons.bag_fill),
            label: 'Chợ tuyển dụng',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            activeIcon: const Icon(CupertinoIcons.settings_solid),
            label: l10n?.navPersonal ?? 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialBottomBar(
    BuildContext context,
    AppLocalizations? l10n,
    String assistantName,
  ) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.smart_toy_outlined),
          selectedIcon: const Icon(Icons.smart_toy_rounded),
          label: assistantName,
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Nhân viên',
        ),
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Chợ tuyển dụng',
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l10n?.navPersonal ?? 'Cài đặt',
        ),
      ],
    );
  }
}

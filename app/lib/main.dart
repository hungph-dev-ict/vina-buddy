import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/config/constants.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';
import 'package:smart_inbox_ai/theme/app_theme.dart';
import 'package:smart_inbox_ai/screens/auth_screen.dart';
import 'package:smart_inbox_ai/screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SmartInboxApp(),
    ),
  );
}

class SmartInboxApp extends ConsumerWidget {
  const SmartInboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appName ?? AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.isAuthenticated
          ? const MainNavigationScreen()
          : const AuthScreen(),
    );
  }
}


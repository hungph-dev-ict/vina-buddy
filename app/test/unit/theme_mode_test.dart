import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';

void main() {
  group('ThemeModeNotifier', () {
    test('defaults to ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('sets theme mode to light and dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggles theme correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      notifier.setThemeMode(ThemeMode.light);
      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}

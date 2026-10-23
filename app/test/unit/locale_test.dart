import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';

void main() {
  group('LocaleNotifier', () {
    test('defaults to English locale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale.languageCode, equals('en'));
    });

    test('updates locale when setLocale is called', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('vi'));
      expect(container.read(localeProvider).languageCode, equals('vi'));

      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      expect(container.read(localeProvider).languageCode, equals('en'));
    });

    test('toggles between English and Vietnamese', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider).languageCode, equals('en'));

      container.read(localeProvider.notifier).toggleLocale();
      expect(container.read(localeProvider).languageCode, equals('vi'));

      container.read(localeProvider.notifier).toggleLocale();
      expect(container.read(localeProvider).languageCode, equals('en'));
    });
  });
}

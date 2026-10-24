import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/l10n/app_localizations.dart';
import 'package:smart_inbox_ai/providers/app_providers.dart';

class LanguageSelectorAction extends ConsumerWidget {
  final bool isCompact;

  const LanguageSelectorAction({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<Locale>(
      tooltip: l10n?.selectLanguage ?? 'Language',
      icon: isCompact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 18),
                const SizedBox(width: 4),
                Text(
                  currentLocale.languageCode.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : null,
      initialValue: currentLocale,
      onSelected: (locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Row(
            children: [
              const Text('🇺🇸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                l10n?.languageEn ?? 'English',
                style: TextStyle(
                  fontWeight: currentLocale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (currentLocale.languageCode == 'en') ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: Colors.blue),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('vi'),
          child: Row(
            children: [
              const Text('🇻🇳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                l10n?.languageVi ?? 'Tiếng Việt',
                style: TextStyle(
                  fontWeight: currentLocale.languageCode == 'vi'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (currentLocale.languageCode == 'vi') ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: Colors.blue),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

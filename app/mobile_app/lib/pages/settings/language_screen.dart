import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../ui/app_responsive.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return AppPageScaffold(
      title: l10n.settingsLanguage,
      navigationBarStyle: AppNavigationBarStyle.compact,
      maxContentWidth: AppResponsive.readableMaxWidth(context, fallback: 720),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _LanguageOption(
            label: l10n.followSystem,
            selected: currentLocale == null,
            onTap: () => _selectLocale(ref, null),
          ),
          const SizedBox(height: 8),
          for (final locale in supportedLocales)
            _LanguageOption(
              label: _localeLabel(locale, l10n),
              selected: currentLocale == locale,
              onTap: () => _selectLocale(ref, locale),
            ),
        ],
      ),
    );
  }

  String _localeLabel(Locale locale, AppLocalizations l10n) {
    return switch (locale.languageCode) {
      'zh' => l10n.language_zh,
      'en' => l10n.language_en,
      'ja' => l10n.language_ja,
      'ru' => l10n.language_ru,
      'fr' => l10n.language_fr,
      'de' => l10n.language_de,
      'ko' => l10n.language_ko,
      _ => locale.toString(),
    };
  }

  void _selectLocale(WidgetRef ref, Locale? locale) {
    ref.read(localeNotifierProvider.notifier).setLocale(locale);
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTappableCard(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: AppRadii.lg,
      showShadow: false,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(context),
            ),
          ),
          if (selected)
            Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: CupertinoDynamicColor.resolve(
                AppColors.primary,
                context,
              ),
              size: 22,
            ),
        ],
      ),
    );
  }
}

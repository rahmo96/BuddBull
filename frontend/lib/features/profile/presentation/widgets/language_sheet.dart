import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _currentLabel(BuildContext context, Locale? locale) {
  switch (locale?.languageCode) {
    case 'en':
      return context.l10n.languageEnglish;
    case 'he':
      return context.l10n.languageHebrew;
    default:
      return context.l10n.languageDeviceDefault;
  }
}

class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return ListTile(
      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
      title: Text(
        context.l10n.languageTitle,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _currentLabel(context, locale),
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: () => showLanguageSheet(context),
    );
  }
}

Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(localeProvider);
        final notifier = ref.read(localeProvider.notifier);

        Widget option(String label, Locale? value) {
          final selected = current?.languageCode == value?.languageCode;
          return ListTile(
            title: Text(label),
            trailing: selected
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () async {
              await notifier.setLocale(value);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(context.l10n.languageDeviceDefault, null),
              option(context.l10n.languageEnglish, const Locale('en')),
              option(context.l10n.languageHebrew, const Locale('he')),
            ],
          ),
        );
      },
    ),
  );
}

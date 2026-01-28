import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/font_size_provider.dart';
import '../../../l10n/app_strings.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class PreferencesScreen extends StatefulWidget {
  final String? from;

  const PreferencesScreen({super.key, this.from});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late String _language;
  String _frequency = 'daily';
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  final double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _language = context.read<LocaleProvider>().locale;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final localeProvider = context.watch<LocaleProvider>();
    _language = localeProvider.locale;

    return AppPopScope(
      onWillPop: () async {
        if (widget.from == 'profile') {
          context.go('/profile');
        } else {
          context.go('/home');
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: CustomAppBar(title: 'Préférences', isDarkMode: isDarkMode),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, localeProvider.t('language')),
                _buildLanguageSelector(context, isDarkMode, localeProvider),
                const SizedBox(height: AppConstants.paddingLarge),

                _buildSectionTitle(context, localeProvider.t('notifications')),
                _buildCheckboxItem(
                  context: context,
                  title: localeProvider.t('pushNotifications'),
                  description: localeProvider.t('pushNotifications'),
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value ?? false),
                  isDarkMode: isDarkMode,
                  delay: 150,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildCheckboxItem(
                  context: context,
                  title: localeProvider.t('emailNotifications'),
                  description: localeProvider.t('emailNotifications'),
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value ?? false),
                  isDarkMode: isDarkMode,
                  delay: 200,
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                _buildSectionTitle(context, localeProvider.t('frequencyOfAdvice')),
                _buildDropdown(
                  context: context,
                  value: _frequency,
                  items: {
                    'daily': localeProvider.t('daily'),
                    'weekly': localeProvider.t('weekly'),
                    'monthly': localeProvider.t('monthly'),
                    'never': localeProvider.t('never'),
                  },
                  onChanged: (value) =>
                      setState(() => _frequency = value ?? 'daily'),
                  isDarkMode: isDarkMode,
                  delay: 250,
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                _buildSectionTitle(context, localeProvider.t('fontSize')),
                _buildFontSizeSelector(context, isDarkMode, localeProvider),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingSmall,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.animationNormal)
        .slideX(begin: -10, end: 0);
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
    required bool isDarkMode,
    required int delay,
  }) {
    return Card(
          elevation: 0,
          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            side: BorderSide(
              color: isDarkMode
                  ? const Color.fromRGBO(66, 66, 66, 0.3)
                  : const Color.fromRGBO(224, 224, 224, 0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: DropdownButton<String>(
              value: value,
              items: items.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: onChanged,
              isExpanded: true,
              underline: const SizedBox(),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppConstants.animationNormal)
        .slideY(begin: 10, end: 0);
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    bool isDarkMode,
    LocaleProvider localeProvider,
  ) {
    return Card(
      elevation: 0,
      color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        side: BorderSide(
          color: isDarkMode
              ? const Color.fromRGBO(66, 66, 66, 0.3)
              : const Color.fromRGBO(224, 224, 224, 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (String locale in localeProvider.availableLocales)
              RadioListTile<String>(
                title: Text(localeProvider.getLocaleName(locale)),
                value: locale,
                groupValue: localeProvider.locale,
                activeColor: isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                onChanged: (value) async {
                  if (value != null) {
                    await localeProvider.setLocale(value);
                  }
                },
              ),
          ],
        ),
      ),
    ).animate(delay: const Duration(milliseconds: 100)).fadeIn(duration: AppConstants.animationNormal).slideY(begin: 10, end: 0);
  }

  Widget _buildFontSizeSelector(
    BuildContext context,
    bool isDarkMode,
    LocaleProvider localeProvider,
  ) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, _) {
        return Card(
          elevation: 0,
          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            side: BorderSide(
              color: isDarkMode
                  ? const Color.fromRGBO(66, 66, 66, 0.3)
                  : const Color.fromRGBO(224, 224, 224, 0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (FontSize size in fontSizeProvider.availableSizes)
                  RadioListTile<FontSize>(
                    title: Text(fontSizeProvider.getSizeName(size, localeProvider.locale)),
                    value: size,
                    groupValue: fontSizeProvider.fontSize,
                    activeColor: isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    onChanged: (value) async {
                      if (value != null) {
                        await fontSizeProvider.setFontSize(value);
                      }
                    },
                  ),
              ],
            ),
          ),
        ).animate(delay: const Duration(milliseconds: 300)).fadeIn(duration: AppConstants.animationNormal).slideY(begin: 10, end: 0);
      },
    );
  }

  Widget _buildCheckboxItem({
    required BuildContext context,
    required String title,
    required String description,
    required bool value,
    required Function(bool?) onChanged,
    required bool isDarkMode,
    required int delay,
  }) {
    return Card(
          elevation: 0,
          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            side: BorderSide(
              color: isDarkMode
                  ? const Color.fromRGBO(66, 66, 66, 0.3)
                  : const Color.fromRGBO(224, 224, 224, 0.5),
              width: 1,
            ),
          ),
          child: CheckboxListTile(
            title: Text(title, style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(
              description,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
            ),
            value: value,
            onChanged: onChanged,
            activeColor: isDarkMode
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppConstants.animationNormal)
        .slideY(begin: 10, end: 0);
  }
}

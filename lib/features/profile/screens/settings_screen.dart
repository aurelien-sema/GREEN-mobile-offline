import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  final String? from;

  const SettingsScreen({super.key, this.from});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _analyticsKey = 'settings_analytics_enabled';

  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsPreference();
  }

  Future<void> _loadAnalyticsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _analyticsEnabled = prefs.getBool(_analyticsKey) ?? true);
  }

  Future<void> _setAnalyticsEnabled(bool value) async {
    setState(() => _analyticsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final themeProvider = context.read<ThemeProvider>();
    final t = context.watch<LocaleProvider>().t;

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
        appBar: CustomAppBar(title: t('settingsLabel'), isDarkMode: isDarkMode),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, t('appearance')),
                _buildSettingItem(
                  context: context,
                  title: t('darkModeToggle'),
                  description: t('toggleDarkThemeDesc'),
                  icon: Icons.dark_mode,
                  isDarkMode: isDarkMode,
                  onToggle: (value) => themeProvider.toggleTheme(),
                  value: isDarkMode,
                  delay: 100,
                ),
                const SizedBox(height: AppConstants.paddingMedium),



                _buildSectionTitle(context, t('privacy')),
                _buildSettingItem(
                  context: context,
                  title: t('dataSharing'),
                  description: t('allowDataAnalysisDesc'),
                  icon: Icons.privacy_tip,
                  isDarkMode: isDarkMode,
                  onToggle: _setAnalyticsEnabled,
                  value: _analyticsEnabled,
                  delay: 200,
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                // Version Info
                Card(
                      elevation: 0,
                      color: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                        side: BorderSide(
                          color: isDarkMode
                              ? const Color.fromRGBO(66, 66, 66, 0.3)
                              : const Color.fromRGBO(224, 224, 224, 0.5),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('aboutTheApp'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              t('version'),
                              '1.0.0',
                              isDarkMode,
                            ),
                            _buildInfoRow(
                              context,
                              t('buildLabel'),
                              'v1.0.0+1',
                              isDarkMode,
                            ),
                            _buildInfoRow(
                              context,
                              t('lastUpdate'),
                              '19 janvier 2026',
                              isDarkMode,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 250))
                    .fadeIn(duration: AppConstants.animationNormal)
                    .slideY(begin: 10, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingSmall,
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.animationNormal)
        .slideX(begin: -10, end: 0);
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isDarkMode,
    required Function(bool) onToggle,
    required bool value,
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
              vertical: AppConstants.paddingSmall,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                  ),
                  child: Icon(
                    icon,
                    color: isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDarkMode
                              ? AppColors.darkHint
                              : AppColors.lightHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onToggle,
                  activeThumbColor: isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  inactiveTrackColor: isDarkMode
                      ? const Color.fromRGBO(66, 66, 66, 0.3)
                      : const Color.fromRGBO(224, 224, 224, 0.5),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppConstants.animationNormal)
        .slideY(begin: 10, end: 0);
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  final String? from;

  const SettingsScreen({super.key, this.from});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final themeProvider = context.read<ThemeProvider>();

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
        appBar: CustomAppBar(title: 'Paramètres', isDarkMode: isDarkMode),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Apparence'),
                _buildSettingItem(
                  context: context,
                  title: 'Mode sombre',
                  description: 'Basculer vers le thème sombre',
                  icon: Icons.dark_mode,
                  isDarkMode: isDarkMode,
                  onToggle: (value) {
                    setState(() => _darkModeEnabled = value);
                    themeProvider.toggleTheme();
                  },
                  value: _darkModeEnabled || isDarkMode,
                  delay: 100,
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                _buildSectionTitle(context, 'Notifications'),
                _buildSettingItem(
                  context: context,
                  title: 'Notifications',
                  description: 'Recevoir les alertes',
                  icon: Icons.notifications,
                  isDarkMode: isDarkMode,
                  onToggle: (value) =>
                      setState(() => _notificationsEnabled = value),
                  value: _notificationsEnabled,
                  delay: 150,
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                _buildSectionTitle(context, 'Confidentialité'),
                _buildSettingItem(
                  context: context,
                  title: 'Partage de données',
                  description: 'Permettre l\'analyse de données',
                  icon: Icons.privacy_tip,
                  isDarkMode: isDarkMode,
                  onToggle: (value) =>
                      setState(() => _analyticsEnabled = value),
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
                              'À propos de l\'application',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              'Version',
                              '1.0.0',
                              isDarkMode,
                            ),
                            _buildInfoRow(
                              context,
                              'Build',
                              'v1.0.0+1',
                              isDarkMode,
                            ),
                            _buildInfoRow(
                              context,
                              'Dernière mise à jour',
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
                Icon(
                  icon,
                  color: isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  size: 24,
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

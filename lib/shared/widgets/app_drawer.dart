import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/extensions/context_extensions.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onThemeToggle;

  const AppDrawer({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;

    return SafeArea(
      child: Drawer(
        backgroundColor: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: isDarkMode
                    ? AppColors.darkGradient
                    : AppColors.lightGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 40,
                      color: Color(0xFF2E8B57),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Green',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    t('appSlogan'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color.fromRGBO(255, 255, 255, 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: t('home'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
              isDarkMode: isDarkMode,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.camera_alt,
              title: t('scanner'),
              onTap: () {
                Navigator.pop(context);
                context.go('/camera');
              },
              isDarkMode: isDarkMode,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat_bubble,
              title: t('chatAI'),
              onTap: () {
                Navigator.pop(context);
                context.go('/chat');
              },
              isDarkMode: isDarkMode,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: t('profile'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
              isDarkMode: isDarkMode,
            ),

            const Divider(),

            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              child: Text(
                t('settingsSectionHeader'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Theme Toggle
            _buildThemeToggle(context, isDarkMode),

            // Language Settings
            _buildDrawerItem(
              context,
              icon: Icons.language,
              title: t('language'),
              onTap: () {
                Navigator.pop(context);
                _showLanguageDialog(context);
              },
              isDarkMode: isDarkMode,
            ),

            // Preferences
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: t('preferences'),
              onTap: () {
                Navigator.pop(context);
                context.push('/preferences');
              },
              isDarkMode: isDarkMode,
            ),

            // Settings
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: t('settingsLabel'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
              isDarkMode: isDarkMode,
            ),

            const Divider(),

            // Support Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              child: Text(
                t('supportSectionHeader'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // About
            _buildDrawerItem(
              context,
              icon: Icons.info,
              title: t('about'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
              isDarkMode: isDarkMode,
            ),

            // Help
            _buildDrawerItem(
              context,
              icon: Icons.help,
              title: t('help'),
              onTap: () {
                Navigator.pop(context);
                context.showSnackBarMessage(t('helpCenterComingSoon'));
              },
              isDarkMode: isDarkMode,
            ),

            const Divider(),

            // Logout
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: t('logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
              isDarkMode: isDarkMode,
              isDestructive: true,
            ),

            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? AppColors.lightError
            : (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDestructive ? AppColors.lightError : null,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDarkMode) {
    final themeProvider = context.read<ThemeProvider>();
    final t = context.read<LocaleProvider>().t;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                t('darkTheme'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeThumbColor: AppColors.lightPrimary,
              inactiveThumbColor: AppColors.lightHint,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final t = context.read<LocaleProvider>().t;

    showDialog(
      context: context,
      builder: (context) {
        final localeProvider = context.read<LocaleProvider>();
        return AlertDialog(
          title: Text(t('selectLanguageTitle')),
          backgroundColor: isDarkMode
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, localeProvider.getLocaleName('fr'), 'fr', localeProvider),
              _buildLanguageOption(context, localeProvider.getLocaleName('en'), 'en', localeProvider),
              _buildLanguageOption(context, localeProvider.getLocaleName('pid'), 'pid', localeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String name,
    String code,
    LocaleProvider localeProvider,
  ) {
    return ListTile(
      title: Text(name),
      onTap: () async {
        final message = context.read<LocaleProvider>().t('languageChangedTo').replaceAll('{name}', name);
        await localeProvider.setLocale(code);
        if (!context.mounted) return;
        Navigator.pop(context);
        context.showSnackBarMessage(message);
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final t = context.read<LocaleProvider>().t;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('aboutGreen')),
        backgroundColor: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t('greenSubtitleFull'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text('${t('version')}: 1.0.0'),
              const SizedBox(height: 8),
              Text(t('smartDiseaseDetectionDesc')),
              const SizedBox(height: 16),
              Text('${t('usingLabel')}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('• Flutter 3.10+'),
              const Text('• Google Gemini 2.5 Flash'),
              Text('• ${t('mlTechnologies')}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('closeDialog')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final t = context.read<LocaleProvider>().t;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('logout')),
        content: Text(t('confirmLogoutMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              // Invalider la session avant de naviguer — sinon l'utilisateur
              // reste authentifié et splash_screen le renvoie directement sur
              // /home au prochain lancement (même bug que profile_screen,
              // corrigé ici aussi).
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text(
              t('logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

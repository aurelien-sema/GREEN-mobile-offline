import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onThemeToggle;

  const AppDrawer({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

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
                    'Naturellement Intelligent',
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
              title: 'Accueil',
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
              isDarkMode: isDarkMode,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.camera_alt,
              title: 'Scanner',
              onTap: () {
                Navigator.pop(context);
                context.go('/camera');
              },
              isDarkMode: isDarkMode,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat_bubble,
              title: 'Chat IA',
              onTap: () {
                Navigator.pop(context);
                context.go('/chat');
              },
              isDarkMode: isDarkMode,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Profil',
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
                'PARAMÈTRES',
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
              title: 'Langue',
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
              title: 'Préférences',
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
              title: 'Paramètres',
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
                'SUPPORT',
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
              title: 'À propos',
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
              title: 'Aide',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Centre d\'aide - À venir')),
                );
              },
              isDarkMode: isDarkMode,
            ),

            const Divider(),

            // Logout
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Déconnexion',
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
                'Thème sombre',
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

    showDialog(
      context: context,
      builder: (context) {
        final localeProvider = context.read<LocaleProvider>();
        return AlertDialog(
          title: const Text('Sélectionner la langue'),
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
        await localeProvider.setLocale(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Langue changée en $name')));
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de Green'),
        backgroundColor: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Green - Naturellement Intelligent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text('Détection intelligente de maladies des plantes avec IA'),
              SizedBox(height: 16),
              Text('Utilisant:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Flutter 3.10+'),
              Text('• Google Gemini 1.5 Flash'),
              Text('• Technologies d\'apprentissage automatique'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

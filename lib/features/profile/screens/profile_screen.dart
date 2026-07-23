import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/history_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/profile_image_service.dart';
import '../../../shared/widgets/app_pop_scope.dart';

class ProfileScreen extends StatefulWidget {
  final String? from;
  const ProfileScreen({super.key, this.from});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  late StreamSubscription<void> _histSub;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
    _histSub = historyService.onChanged.listen((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    try {
      final s = await historyService.getStatistics();
      if (mounted) setState(() => _stats = s);
    } catch (_) {
      if (mounted) setState(() => _stats = null);
    }
  }

  Future<void> _showImagePickerOptions(BuildContext context) async {
    final t = context.read<LocaleProvider>().t;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t('gallery')),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t('cameraSource')),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final cropTitle = context.read<LocaleProvider>().t('cropPhotoTitle');
      final path = await profileImageService.pickAndSaveImage(source, cropTitle: cropTitle);
      if (path != null && mounted) {
        final auth = context.read<AuthProvider>();
        final currentUser = auth.currentUser;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(avatarUrl: path);
          await auth.updateProfile(updatedUser);
        }
      }
    } catch (e) {
      debugPrint('Error in profile screen pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LocaleProvider>().t('imagePickErrorMessage'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final contact = (user != null && (user.email.isNotEmpty))
        ? user.email
        : (user?.phone ?? '');

    return AppPopScope(
      onWillPop: () async {
        context.go(widget.from ?? '/home');
        return false;
      },
      child: Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(t('profile')),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(widget.from ?? '/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? AppColors.darkGradient
                          : AppColors.lightGradient,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusXLarge,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePickerOptions(context),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color.fromRGBO(255, 255, 255, 0.2),
                                  border: Border.all(color: Colors.white, width: 3),
                                  image: user?.avatarUrl != null
                                      ? DecorationImage(
                                          image: FileImage(File(user!.avatarUrl!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: user?.avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 50,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showImagePickerOptions(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.lightPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().scale(
                          duration: AppConstants.animationNormal,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? t('defaultUserName'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color.fromRGBO(255, 255, 255, 0.9),
                              ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: AppConstants.animationNormal)
                  .slideY(begin: -20, end: 0),
              const SizedBox(height: AppConstants.paddingLarge),

              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      t('scansStat'),
                      _stats != null ? '${_stats!['total'] ?? 0}' : '...',
                      isDarkMode,
                      100,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      t('avgConfidenceStat'),
                      _stats != null
                          ? '${((_stats!['avgConfidence'] ?? 0.0) * 100).round()}%'
                          : '...',
                      isDarkMode,
                      150,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      t('mostFrequentStat'),
                      _stats != null ? (_stats!['mostCommon'] ?? '-') : '...',
                      isDarkMode,
                      200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              // Menu Items
              _buildMenuSection(context, isDarkMode),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode,
    int delay,
  ) {
    return Card(
          elevation: 0,
          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            side: BorderSide(
              color: isDarkMode
                  ? const Color.fromRGBO(66, 66, 66, 0.3)
                  : const Color.fromRGBO(224, 224, 224, 0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppConstants.animationNormal)
        .slideY(begin: 10, end: 0);
  }

  Widget _buildMenuSection(BuildContext context, bool isDarkMode) {
    final t = context.read<LocaleProvider>().t;
    final menuItems = [
      (t('settingsLabel'), Icons.settings, '/settings'),
      (t('preferences'), Icons.tune, '/preferences'),
      (t('about'), Icons.info, '/about'),
      (t('logout'), Icons.logout, '/login'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('menu'), style: Theme.of(context).textTheme.headlineSmall)
            .animate(delay: const Duration(milliseconds: 250))
            .fadeIn(duration: AppConstants.animationNormal),
        const SizedBox(height: AppConstants.paddingMedium),
        ...List.generate(
          menuItems.length,
          (index) => _buildMenuItem(
            context,
            menuItems[index].$1,
            menuItems[index].$2,
            menuItems[index].$3,
            isDarkMode,
            300 + (index * 50),
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildDeleteAccountButton(context, isDarkMode),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    String? route,
    bool isDarkMode,
    int delay,
  ) {
    return GestureDetector(
      onTap: () async {
        if (route == '/login') {
          // "Se déconnecter" : invalider la session avant de naviguer,
          // sinon l'utilisateur reste authentifié et splash_screen le
          // renvoie directement sur /home au prochain lancement.
          await context.read<AuthProvider>().logout();
          if (!context.mounted) return;
          context.go('/login');
          return;
        }
        if (route != null) {
          context.go(route, extra: {'from': 'profile'});
        }
      },
      child:
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
                margin: const EdgeInsets.only(
                  bottom: AppConstants.paddingSmall,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingMedium,
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
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode
                            ? AppColors.darkHint
                            : AppColors.lightHint,
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: delay))
              .fadeIn(duration: AppConstants.animationNormal)
              .slideX(begin: 10, end: 0),
    );
  }

  @override
  void dispose() {
    try {
      _histSub.cancel();
    } catch (_) {}
    super.dispose();
  }

  /// Build delete account button (red text)
  Widget _buildDeleteAccountButton(BuildContext context, bool isDarkMode) {
    final t = context.read<LocaleProvider>().t;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t('deleteAccount')),
            content: Text(
              t('confirmIrreversibleAction'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _deleteAccount();
                },
                child: Text(
                  t('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingMedium,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(244, 67, 54, 0.12),
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Text(
                  t('deleteAccount'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  /// Delete account logic
  Future<void> _deleteAccount() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final contact = user.email.isNotEmpty ? user.email : (user.phone ?? '');
    try {
      // Delete from auth service
      final deleted =
          await authService.deleteUserByIdentifier(contact);
      if (!deleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<LocaleProvider>().t('userNotFoundError'))),
          );
        }
        return;
      }

      // Logout
      await auth.logout();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.read<LocaleProvider>().t('errorPrefix')}: $e')),
        );
      }
    }
  }
}
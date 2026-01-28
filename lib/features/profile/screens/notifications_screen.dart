import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  final String? from;

  const NotificationsScreen({super.key, this.from});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Maladie détectée',
      'message': 'Oïdium détecté sur votre plante',
      'timestamp': '2 heures',
      'icon': Icons.warning,
      'read': false,
    },
    {
      'title': 'Conseil IA',
      'message': 'Pensez à arroser vos plantes',
      'timestamp': '5 heures',
      'icon': Icons.lightbulb,
      'read': false,
    },
    {
      'title': 'Mise à jour',
      'message': 'Nouvelle version disponible',
      'timestamp': '1 jour',
      'icon': Icons.update,
      'read': true,
    },
    {
      'title': 'Succès',
      'message': 'Vous avez guéri 5 plantes!',
      'timestamp': '3 jours',
      'icon': Icons.celebration,
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    context.read<ThemeProvider>();

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
        appBar: CustomAppBar(title: 'Notifications', isDarkMode: isDarkMode),
        body: SafeArea(
          child: _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: isDarkMode
                            ? AppColors.darkHint
                            : AppColors.lightHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(
                      context,
                      notification,
                      index,
                      isDarkMode,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
    bool isDarkMode,
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
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isDarkMode
                        ? AppColors.darkGradient
                        : AppColors.lightGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification['icon'],
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification['title'],
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (!notification['read'])
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDarkMode
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode
                              ? AppColors.darkHint
                              : AppColors.lightHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['timestamp'],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDarkMode
                              ? AppColors.darkHint
                              : AppColors.lightHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: AppConstants.animationNormal)
        .slideY(begin: 10, end: 0);
  }
}

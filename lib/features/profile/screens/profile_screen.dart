import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_history_service.dart';
import '../../../services/green_web/photo_sync_service.dart';
import '../../../services/history_service.dart';
import '../../../services/profile_image_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../utils/date_formatter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<HistoryStats> _stats = historyService.statistics();

  Future<void> _changePhoto() async {
    final t = context.read<LocaleProvider>().t;
    final user = context.read<AuthProvider>().currentUser;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t('takePhoto')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t('gallery')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (user?.avatarPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error),
                title: Text(t('removePhoto'), style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || user == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (choice == 'remove') {
      final ok = await showConfirmDialog(
        context,
        title: t('removePhoto'),
        message: t('removePhotoConfirm'),
        confirmLabel: t('delete'),
        cancelLabel: t('cancel'),
        destructive: true,
      );
      if (!ok) return;
      await profileImageService.delete(user.avatarPath);
      await authService.setAvatarPath(user.id, null);
      await auth.refresh();
      return;
    }
    try {
      final path = await profileImageService.pickAndStore(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        userId: user.id,
        cropTitle: t('cropPhotoTitle'),
        toolbarColor: Theme.of(context).colorScheme.primary,
      );
      if (path == null) return;
      final previous = user.avatarPath;
      await authService.setAvatarPath(user.id, path);
      if (previous != null && previous != path) await profileImageService.delete(previous);
      await auth.refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('imagePickErrorMessage'))));
    }
  }

  Future<void> _logout() async {
    final t = context.read<LocaleProvider>().t;
    final ok = await showConfirmDialog(
      context,
      title: t('logout'),
      message: t('logoutConfirm'),
      confirmLabel: t('logout'),
      cancelLabel: t('cancel'),
    );
    if (!ok || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  Future<void> _deleteAccount() async {
    final t = context.read<LocaleProvider>().t;
    final auth = context.read<AuthProvider>();
    final sync = context.read<PhotoSyncService>();
    final user = auth.currentUser;
    if (user == null) return;
    final password = await showPasswordPrompt(
      context,
      title: t('deleteAccount'),
      message: t('deleteAccountConfirm'),
      fieldLabel: t('currentPassword'),
      confirmLabel: t('delete'),
      cancelLabel: t('cancel'),
      destructive: true,
    );
    if (password == null || !mounted) return;
    final ok = await authService.deleteAccount(user.id, password);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('wrongCurrentPassword'))));
      return;
    }
    await historyService.deleteAllFor(user.id);
    await chatHistoryService.deleteAllFor(user.id);
    await profileImageService.delete(user.avatarPath);
    await sync.forget(user.id);
    await auth.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('accountDeleted'))));
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final user = context.watch<AuthProvider>().currentUser;
    final catalog = context.watch<DiseasesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t('profile'))),
      body: SafeArea(
        top: false,
        child: user == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: () async => setState(() => _stats = historyService.statistics()),
              child: ListView(
                padding: Spacing.page,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _changePhoto,
                          child: UserAvatar(user: user, radius: 52),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton.filled(
                            tooltip: t('changePhoto'),
                            onPressed: _changePhoto,
                            icon: const Icon(Icons.photo_camera_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.gapBlock,
                  Text(user.name, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  Text(
                    user.contact,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.tf('memberSince', {'date': formatDate(user.memberSince, l.locale)}),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<HistoryStats>(
                    future: _stats,
                    builder: (context, snap) {
                      final s = snap.data;
                      final top = catalog.findById(s?.mostFrequentDiseaseId) ?? catalog.findByModelLabel(s?.mostFrequentDiseaseId);
                      return Column(
                        children: [
                          Row(
                            children: [
                              _Stat(value: '${s?.total ?? '–'}', label: t('scansStat')),
                              const SizedBox(width: 8),
                              _Stat(value: '${s?.diseased ?? '–'}', label: t('filterDiseased')),
                              const SizedBox(width: 8),
                              _Stat(value: '${s?.healthy ?? '–'}', label: t('filterHealthy')),
                            ],
                          ),
                          if (top != null) ...[
                            const SizedBox(height: 8),
                            SectionCard(
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up_rounded, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l.tf('mostFrequentIs', {'name': top.name.of(l.locale)}))),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  GroupLabel(t('myActivity')),
                  SettingsGroup(children: [
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(t('history')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/history'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: Text(t('diseasesLibrary')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/diseases'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined),
                      title: Text(t('detailedWeather')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/weather'),
                    ),
                  ]),
                  GroupLabel(t('settingsSectionHeader')),
                  SettingsGroup(children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(t('settingsLabel')),
                      subtitle: Text(t('settingsSubtitle')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(t('about')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/about'),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout_rounded), label: Text(t('logout'))),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(t('deleteAccount')),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 2),
              Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

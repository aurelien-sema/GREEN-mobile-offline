import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/validation/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/font_size_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_history_service.dart';
import '../../../services/green_web/photo_sync_service.dart';
import '../../../services/history_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../utils/date_formatter.dart';
import '../../auth/widgets/auth_header.dart';

/// Paramètres (fusion des anciens écrans « Paramètres » et « Préférences »).
///
/// Réglages rendus réellement effectifs en v2 : la taille du texte s'applique
/// à toute l'application (elle était enregistrée mais jamais appliquée) ; le
/// partage des données pilote l'envoi vers GREEN Web. Le réglage « fréquence
/// des conseils », sans aucun effet (l'application n'envoie pas de
/// notifications), a été retiré.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final theme = context.watch<ThemeProvider>();
    final font = context.watch<FontSizeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t('settingsLabel'))),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(Spacing.gutter, 0, Spacing.gutter, 40),
        children: [
          GroupLabel(t('appearance')),
          SectionCard(
            title: t('themeLabel'),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(t('lightTheme')), icon: const Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text(t('darkTheme')), icon: const Icon(Icons.dark_mode_outlined)),
              ],
              selected: {theme.themeMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light},
              onSelectionChanged: (s) => theme.setTheme(s.first),
            ),
          ),
          Spacing.gapBlock,
          SectionCard(
            title: t('fontSize'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<FontSize>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in FontSize.values)
                      ButtonSegment(value: s, label: Text('A', style: TextStyle(fontSize: 13 * s.scale))),
                  ],
                  selected: {font.fontSize},
                  onSelectionChanged: (s) => font.setFontSize(s.first),
                ),
                const SizedBox(height: 8),
                Text(font.getSizeName(font.fontSize, l.locale)),
              ],
            ),
          ),
          GroupLabel(t('language')),
          SettingsGroup(dividerIndent: 20, children: [
            for (final code in l.availableLocales)
              ListTile(
                title: Text(l.getLocaleName(code)),
                trailing: l.locale == code ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () => l.setLocale(code),
              ),
          ]),
          GroupLabel(t('dataAndSync')),
          const _GreenWebSection(),
          GroupLabel(t('security')),
          SettingsGroup(children: [
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: Text(t('changePassword')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _changePassword(context),
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: Text(t('changeSecurityQuestion')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/security-question'),
            ),
          ]),
          GroupLabel(t('storage')),
          SettingsGroup(children: [
            ListTile(
              leading: const Icon(Icons.history_toggle_off_rounded),
              title: Text(t('clearHistoryTitle')),
              onTap: () => _clearHistory(context),
            ),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: Text(t('clearChatsTitle')),
              onTap: () => _clearChats(context),
            ),
          ]),
          GroupLabel(t('about')),
          SettingsGroup(children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(t('aboutTheApp')),
              subtitle: Text('${t('version')} ${AppInfo.fullVersion}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/about'),
            ),
          ]),
        ],
      ),
      )
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    final t = context.read<LocaleProvider>().t;
    final ok = await showConfirmDialog(
      context,
      title: t('clearHistoryTitle'),
      message: t('clearHistoryMessage'),
      confirmLabel: t('deleteAll'),
      cancelLabel: t('cancel'),
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final sync = context.read<PhotoSyncService>();
    final uid = context.read<AuthProvider>().currentUser?.id;
    await historyService.clearAll();
    if (uid != null) await sync.forget(uid);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('historyCleared'))));
  }

  Future<void> _clearChats(BuildContext context) async {
    final t = context.read<LocaleProvider>().t;
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    final ok = await showConfirmDialog(
      context,
      title: t('clearChatsTitle'),
      message: t('clearChatsMessage'),
      confirmLabel: t('deleteAll'),
      cancelLabel: t('cancel'),
      destructive: true,
    );
    if (!ok) return;
    await chatHistoryService.deleteAllFor(uid);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('chatsCleared'))));
  }

  Future<void> _changePassword(BuildContext context) async {
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    await showDialog<void>(context: context, builder: (_) => _ChangePasswordDialog(accountId: uid));
  }
}

class _GreenWebSection extends StatelessWidget {
  const _GreenWebSection();

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final sync = context.watch<PhotoSyncService>();
    final theme = Theme.of(context);

    final String status;
    if (!sync.isConfigured) {
      status = t('syncNotConfigured');
    } else if (sync.pendingCount == 0) {
      status = sync.lastSentAt == null
          ? t('syncAllSent')
          : l.tf('syncLastSent', {'time': formatTime(sync.lastSentAt!.toLocal())});
    } else {
      status = l.tf(sync.pendingCount == 1 ? 'pendingPhotosOne' : 'pendingPhotos', {'n': sync.pendingCount});
    }
    final hint = switch (sync.lastError) {
      null => null,
      'offline' => t('syncOfflineHint'),
      'rejected' || 'disabled' || 'not-configured' => t('syncAccountHint'),
      _ => sync.pendingCount > 0 ? t('syncErrorHint') : null,
    };

    return SettingsGroup(children: [
      // Réglage verrouillé : l'envoi fait partie du service et ne se coupe pas.
      ListTile(
        leading: const Icon(Icons.cloud_upload_outlined),
        title: Text(t('uploadPhotos')),
        subtitle: Text(t('uploadPhotosAlwaysOn')),
        trailing: Tooltip(
          message: t('uploadPhotosLocked'),
          child: Icon(Icons.lock_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      ListTile(
        leading: sync.isRunning
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Icon(
                sync.pendingCount == 0 ? Icons.cloud_done_rounded : (sync.isOnline ? Icons.sync_rounded : Icons.cloud_off_rounded),
                color: sync.pendingCount == 0 ? theme.colorScheme.primary : null,
              ),
        title: Text(status),
        subtitle: Text(hint ?? sync.serverUrl.replaceFirst('https://', ''), style: hint == null ? theme.textTheme.bodySmall : null),
        trailing: sync.pendingCount == 0
            ? null
            : TextButton(
                onPressed: sync.isRunning ? null : () => sync.syncNow(lang: l.locale),
                child: Text(t('sendNow')),
              ),
      ),
    ]);
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final String accountId;
  const _ChangePasswordDialog({required this.accountId});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.read<LocaleProvider>().t;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await authService.changePassword(widget.accountId, _current.text, _next.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = t('wrongCurrentPassword');
      });
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('passwordChanged'))));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    return AlertDialog(
      title: Text(t('changePassword')),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PasswordFormField(
                  controller: _current,
                  label: t('currentPassword'),
                  showTooltip: t('showPassword'),
                  hideTooltip: t('hidePassword'),
                  validator: (v) => (v ?? '').isEmpty ? t('errPasswordRequired') : null,
                ),
                Spacing.gapBlock,
                PasswordFormField(
                  controller: _next,
                  label: t('newPassword'),
                  helper: t('passwordRules'),
                  isNewPassword: true,
                  showTooltip: t('showPassword'),
                  hideTooltip: t('hidePassword'),
                  validator: (v) {
                    final e = Validators.newPassword(v);
                    return e == null ? null : t(e);
                  },
                ),
                Spacing.gapBlock,
                PasswordFormField(
                  controller: _confirm,
                  label: t('confirmPassword'),
                  isNewPassword: true,
                  action: TextInputAction.done,
                  showTooltip: t('showPassword'),
                  hideTooltip: t('hidePassword'),
                  validator: (v) {
                    final e = Validators.confirmPassword(v, _next.text);
                    return e == null ? null : t(e);
                  },
                  onSubmitted: (_) => _save(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(t('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _busy ? null : _save,
          child: Text(t('save')),
        ),
      ],
    );
  }
}

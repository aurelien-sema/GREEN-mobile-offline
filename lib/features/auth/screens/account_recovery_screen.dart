import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/utils/text_input_formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/auth/security_questions.dart';
import '../../../services/auth_service.dart';
import '../../../shared/ui/ui.dart';
import '../widgets/auth_header.dart';

/// Vérification d'identité après trois échecs de connexion : l'utilisateur
/// saisit son nom complet et répond à SA question de sécurité. Si les deux
/// sont justes, il choisit un nouveau mot de passe et il est connecté.
class AccountRecoveryScreen extends StatefulWidget {
  final String identifier;
  final String questionId;
  const AccountRecoveryScreen({super.key, required this.identifier, required this.questionId});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _verifyForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _grantedAccountId;
  bool _busy = false;
  String? _error;
  bool _locked = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _answerCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    final l = context.read<LocaleProvider>();
    FocusScope.of(context).unfocus();
    if (!(_verifyForm.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await authService.answerChallenge(
      identifier: widget.identifier,
      fullName: _nameCtrl.text,
      answer: _answerCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case ChallengeSuccess(:final accountId):
          _grantedAccountId = accountId;
        case ChallengeWrong(:final attemptsLeft):
          _error = l.tf(attemptsLeft == 1 ? 'challengeWrongOne' : 'challengeWrong', {'n': attemptsLeft});
        case ChallengeLocked(:final until):
          _locked = true;
          _error = l.tf('challengeLocked', {'n': until.difference(DateTime.now()).inMinutes + 1});
        case ChallengeUnavailable():
          _locked = true;
          _error = l.t('challengeUnavailable');
      }
    });
  }

  Future<void> _savePassword() async {
    final l = context.read<LocaleProvider>();
    FocusScope.of(context).unfocus();
    if (!(_passwordForm.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final account = await authService.completeRecovery(_grantedAccountId!, _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (account == null) {
      setState(() {
        _grantedAccountId = null;
        _error = l.t('recoveryExpired');
      });
      return;
    }
    TextInput.finishAutofillContext();
    await context.read<AuthProvider>().signIn(account);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('passwordChanged'))));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t('verifyIdentity'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Spacing.form,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _grantedAccountId == null ? _verifyStep(l, theme) : _passwordStep(l),
          ),
        ),
      ),
    );
  }

  Widget _verifyStep(LocaleProvider l, ThemeData theme) {
    final t = l.t;
    return Form(
      key: _verifyForm,
      child: Column(
        key: const ValueKey('verify'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(title: t('tooManyAttempts'), subtitle: t('verifyIdentityExplain'), compact: true),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameCtrl,
            enabled: !_locked,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            inputFormatters: [NameInputFormatter(), LengthLimitingTextInputFormatter(64)],
            decoration: InputDecoration(
              labelText: t('fullName'),
              helperText: t('fullNameAsRegistered'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) {
              final e = Validators.name(v);
              return e == null ? null : t(e);
            },
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Row(
              children: [
                Icon(Icons.agriculture_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(SecurityQuestions.translationKey(widget.questionId)),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _answerCtrl,
            enabled: !_locked,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            inputFormatters: [SingleLineTextFormatter(), LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(
              labelText: t('yourAnswer'),
              prefixIcon: const Icon(Icons.key_rounded),
            ),
            validator: (v) {
              final e = Validators.securityAnswer(v);
              return e == null ? null : t(e);
            },
            onFieldSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 24),
          if (_locked)
            OutlinedButton(onPressed: () => context.go('/login'), child: Text(t('backToLogin')))
          else
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(t('verify')),
            ),
        ],
      ),
    );
  }

  Widget _passwordStep(LocaleProvider l) {
    final t = l.t;
    return AutofillGroup(
      child: Form(
        key: _passwordForm,
        child: Column(
          key: const ValueKey('password'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(title: t('identityConfirmed'), subtitle: t('chooseNewPassword'), compact: true),
            const SizedBox(height: 24),
            PasswordFormField(
              controller: _passwordCtrl,
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
            const SizedBox(height: 16),
            PasswordFormField(
              controller: _confirmCtrl,
              label: t('confirmPassword'),
              isNewPassword: true,
              action: TextInputAction.done,
              showTooltip: t('showPassword'),
              hideTooltip: t('hidePassword'),
              validator: (v) {
                final e = Validators.confirmPassword(v, _passwordCtrl.text);
                return e == null ? null : t(e);
              },
              onSubmitted: (_) => _savePassword(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _savePassword,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(t('saveAndLogin')),
            ),
          ],
        ),
      ),
    );
  }
}

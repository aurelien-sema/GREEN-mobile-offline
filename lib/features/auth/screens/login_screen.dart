import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/text_input_formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/auth_service.dart';
import '../widgets/auth_header.dart';

/// Connexion par téléphone ou e-mail.
///
/// - Les champs sont regroupés dans un AutofillGroup : Android (Google
///   Password Manager ou le gestionnaire installé) propose d'enregistrer les
///   identifiants après une connexion réussie et de les remplir ensuite.
/// - « Se souvenir de moi » garde l'identifiant (jamais le mot de passe).
/// - Après trois échecs sur un compte, la vérification par nom complet et
///   question de sécurité prend le relais (écran AccountRecoveryScreen).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _rememberKey = 'login_remembered_identifier';
  static const _rememberModeKey = 'login_remembered_mode';

  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _usePhone = true;
  bool _obscure = true;
  bool _remember = true;
  bool _busy = false;
  String _fullPhone = '';
  String? _message;
  bool _messageIsError = true;

  @override
  void initState() {
    super.initState();
    _restoreRemembered();
  }

  Future<void> _restoreRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_rememberKey);
    if (id == null || !mounted) return;
    setState(() {
      _usePhone = prefs.getString(_rememberModeKey) != 'email';
      if (_usePhone) {
        _fullPhone = id;
        _phoneCtrl.text = id.startsWith('+237') ? id.substring(4) : id;
      } else {
        _emailCtrl.text = id;
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String get _identifier => _usePhone
      ? (_fullPhone.isNotEmpty ? _fullPhone : _phoneCtrl.text.trim())
      : _emailCtrl.text.trim();

  Future<void> _submit() async {
    final l = context.read<LocaleProvider>();
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    final result = await authService.login(_identifier, _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case LoginSuccess(:final account):
        TextInput.finishAutofillContext(); // propose d'enregistrer les identifiants
        await _saveRemembered();
        if (!mounted) return;
        await context.read<AuthProvider>().signIn(account);
        if (!mounted) return;
        context.go(account.hasSecurityQuestion ? '/home' : '/security-setup');
      case LoginInvalid(:final attemptsLeft):
        setState(() {
          _messageIsError = true;
          _message = attemptsLeft == null
              ? l.t('invalidCredentials')
              : l.tf(attemptsLeft == 1 ? 'loginAttemptsLeftOne' : 'loginAttemptsLeft', {'n': attemptsLeft});
        });
      case LoginChallengeRequired(:final questionId):
        _passwordCtrl.clear();
        context.push('/recover', extra: {'identifier': _identifier, 'questionId': questionId});
      case LoginLocked(:final until, :final noSecurityQuestion):
        final minutes = until.difference(DateTime.now()).inMinutes + 1;
        setState(() {
          _messageIsError = true;
          _message = l.tf(noSecurityQuestion ? 'loginLockedNoQuestion' : 'loginLocked', {'n': minutes});
        });
    }
  }

  Future<void> _saveRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setString(_rememberKey, _identifier);
      await prefs.setString(_rememberModeKey, _usePhone ? 'phone' : 'email');
    } else {
      await prefs.remove(_rememberKey);
      await prefs.remove(_rememberModeKey);
    }
  }

  void _showForgotHelp() {
    final t = context.read<LocaleProvider>().t;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_reset_rounded),
        title: Text(t('forgotPasswordTitle')),
        content: Text(t('forgotPasswordHelp')),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t('understood')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthHeader(title: t('welcomeSimple'), subtitle: t('loginToAccess')),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: true, label: Text(t('phone')), icon: const Icon(Icons.phone_android_rounded)),
                          ButtonSegment(value: false, label: Text(t('email')), icon: const Icon(Icons.alternate_email_rounded)),
                        ],
                        selected: {_usePhone},
                        onSelectionChanged: (s) => setState(() {
                          _usePhone = s.first;
                          _message = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                      if (_usePhone)
                        IntlPhoneField(
                          controller: _phoneCtrl,
                          initialCountryCode: 'CM',
                          languageCode: l.materialLanguage,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          invalidNumberMessage: t('errPhoneInvalid'),
                          pickerDialogStyle: PickerDialogStyle(
                    searchFieldInputDecoration: InputDecoration(labelText: t('searchCountry')),
                  ),
                          decoration: InputDecoration(labelText: t('phoneNumberLabel'), counterText: ''),
                          onChanged: (p) => _fullPhone = p.completeNumber,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        )
                      else
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          autocorrect: false,
                          enableSuggestions: false,
                          inputFormatters: [EmailInputFormatter(), LengthLimitingTextInputFormatter(120)],
                          decoration: InputDecoration(
                            labelText: t('emailAddressLabel'),
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (v) {
                            final e = Validators.email(v);
                            return e == null ? null : t(e);
                          },
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscure,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [LengthLimitingTextInputFormatter(128)],
                        decoration: InputDecoration(
                          labelText: t('password'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: t(_obscure ? 'showPassword' : 'hidePassword'),
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v ?? '').isEmpty ? t('errPasswordRequired') : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v ?? false),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(t('rememberMe')),
                            ),
                          ),
                          TextButton(onPressed: _showForgotHelp, child: Text(t('forgotPassword'))),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Easing.standard,
                        child: _message == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: _InlineMessage(text: _message!, isError: _messageIsError),
                              ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Text(t('loginButton')),
                      ),
                      const SizedBox(height: 16),
                      // Wrap : passe à la ligne sur petit écran ou grande police.
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(t('noAccount'), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                          TextButton(onPressed: () => context.push('/register'), child: Text(t('createAccountLink'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String text;
  final bool isError;
  const _InlineMessage({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.errorContainer : scheme.primaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.info_outline_rounded, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: fg))),
          ],
        ),
      ),
    );
  }
}

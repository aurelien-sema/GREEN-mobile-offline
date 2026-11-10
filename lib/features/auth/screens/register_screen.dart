import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/text_input_formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/auth/security_questions.dart';
import '../../../services/auth_service.dart';
import '../../../shared/ui/ui.dart';
import '../widgets/auth_header.dart';

/// Création de compte en deux étapes :
/// 1. identité et mot de passe ;
/// 2. question de sécurité tirée au hasard parmi quatre, et sa réponse.
///
/// Au plus [AppConstants.maxAccountsPerDevice] comptes par téléphone (voir
/// AccountRegistry) : au-delà, l'inscription est refusée dès l'ouverture.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _identityForm = GlobalKey<FormState>();
  final _answerForm = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  bool _usePhone = true;
  String _fullPhone = '';
  int _step = 0;
  bool _busy = false;
  int? _slotsLeft;
  late final String _questionId = SecurityQuestions.randomId();

  @override
  void initState() {
    super.initState();
    authService.remainingAccountSlots().then((n) {
      if (mounted) setState(() => _slotsLeft = n);
    });
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl, _passwordCtrl, _confirmCtrl, _answerCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_identityForm.currentState?.validate() ?? false) setState(() => _step = 1);
  }

  Future<void> _submit() async {
    final l = context.read<LocaleProvider>();
    FocusScope.of(context).unfocus();
    if (!(_answerForm.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final result = await authService.register(
      name: _nameCtrl.text,
      email: _usePhone ? '' : _emailCtrl.text,
      phone: _usePhone ? (_fullPhone.isNotEmpty ? _fullPhone : _phoneCtrl.text) : '',
      password: _passwordCtrl.text,
      securityQuestionId: _questionId,
      securityAnswer: _answerCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.isSuccess) {
      final key = switch (result.error) {
        RegisterError.phoneTaken => 'duplicatePhoneAccount',
        RegisterError.emailTaken => 'duplicateEmailAccount',
        RegisterError.deviceLimitReached => 'deviceLimitReached',
        RegisterError.none => 'somethingWentWrong',
      };
      if (result.error != RegisterError.deviceLimitReached) setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t(key))));
      return;
    }
    TextInput.finishAutofillContext();
    await context.read<AuthProvider>().signIn(result.account!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('registerSuccess'))));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('createAccount')),
        leading: IconButton(
          tooltip: t('back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: PopScope(
          canPop: _step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _step == 1) setState(() => _step = 0);
          },
          child: _slotsLeft == 0
              ? EmptyState(
                  icon: Icons.no_accounts_rounded,
                  title: t('deviceLimitTitle'),
                  message: l.tf('deviceLimitMessage', {'n': AppConstants.maxAccountsPerDevice}),
                  action: FilledButton(onPressed: () => context.go('/login'), child: Text(t('backToLogin'))),
                )
              : AutofillGroup(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Easing.standardDecelerate,
                    switchOutCurve: Easing.standardAccelerate,
                    child: _step == 0 ? _identityStep(l) : _questionStep(l),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _stepIndicator(String label, int index) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= index ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.labelLarge),
      ],
    );
  }

  Widget _identityStep(LocaleProvider l) {
    final t = l.t;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('identity'),
      padding: Spacing.form,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _identityForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepIndicator(l.tf('stepOf', {'n': 1, 'total': 2}), 0),
            const SizedBox(height: 20),
            Text(t('joinUsToStart'), style: theme.textTheme.bodyLarge),
            if (_slotsLeft != null && _slotsLeft! <= 2) ...[
              const SizedBox(height: 12),
              StatusPill(
                label: l.tf(_slotsLeft == 1 ? 'slotsLeftOne' : 'slotsLeft', {'n': _slotsLeft!}),
                color: Theme.of(context).colorScheme.tertiary,
                icon: Icons.info_outline_rounded,
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              inputFormatters: [NameInputFormatter(), LengthLimitingTextInputFormatter(64)],
              decoration: InputDecoration(
                labelText: t('fullName'),
                helperText: t('fullNameHelper'),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                final e = Validators.name(v);
                return e == null ? null : t(e);
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(t('phone')), icon: const Icon(Icons.phone_android_rounded)),
                ButtonSegment(value: false, label: Text(t('email')), icon: const Icon(Icons.alternate_email_rounded)),
              ],
              selected: {_usePhone},
              onSelectionChanged: (s) => setState(() => _usePhone = s.first),
            ),
            const SizedBox(height: 16),
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
              )
            else
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email, AutofillHints.newUsername],
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
              ),
            const SizedBox(height: 16),
            PasswordFormField(
              controller: _passwordCtrl,
              label: t('password'),
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
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 20),
            Text(
              t('uploadNotice'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _next, child: Text(t('next'))),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t('haveAccount'), textAlign: TextAlign.center),
                TextButton(onPressed: () => context.go('/login'), child: Text(t('loginButton'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionStep(LocaleProvider l) {
    final t = l.t;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('question'),
      padding: Spacing.form,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _answerForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepIndicator(l.tf('stepOf', {'n': 2, 'total': 2}), 1),
            const SizedBox(height: 20),
            Text(t('securityQuestionTitle'), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              t('securityQuestionExplain'),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Row(
                children: [
                  Icon(Icons.agriculture_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(SecurityQuestions.translationKey(_questionId)),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _answerCtrl,
              autofocus: true,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              inputFormatters: [SingleLineTextFormatter(), LengthLimitingTextInputFormatter(60)],
              decoration: InputDecoration(
                labelText: t('yourAnswer'),
                helperText: t('answerHelper'),
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.key_rounded),
              ),
              validator: (v) {
                final e = Validators.securityAnswer(v);
                return e == null ? null : t(e);
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(t('signUpButton')),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _busy ? null : () => setState(() => _step = 0), child: Text(t('back'))),
          ],
        ),
      ),
    );
  }
}

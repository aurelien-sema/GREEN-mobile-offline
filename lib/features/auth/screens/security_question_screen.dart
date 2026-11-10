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

/// Question de sécurité :
/// - [change] = false : obligatoire pour les comptes créés avant la v2 (qui
///   n'en avaient pas), juste après leur connexion ;
/// - [change] = true : depuis Paramètres, une nouvelle question est tirée au
///   hasard et le mot de passe actuel est exigé.
class SecurityQuestionScreen extends StatefulWidget {
  final bool change;
  const SecurityQuestionScreen({super.key, this.change = false});

  @override
  State<SecurityQuestionScreen> createState() => _SecurityQuestionScreenState();
}

class _SecurityQuestionScreenState extends State<SecurityQuestionScreen> {
  final _form = GlobalKey<FormState>();
  final _answerCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late String _questionId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<AuthProvider>().currentUser?.securityQuestionId;
    // En cas de changement, la nouvelle question diffère de l'actuelle.
    do {
      _questionId = SecurityQuestions.randomId();
    } while (widget.change && _questionId == current);
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.read<LocaleProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    FocusScope.of(context).unfocus();
    if (user == null || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final ok = await authService.setSecurityQuestion(
      user.id,
      _questionId,
      _answerCtrl.text,
      currentPassword: widget.change ? _passwordCtrl.text : null,
      trustedSession: !widget.change,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('wrongCurrentPassword'))));
      return;
    }
    await auth.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('securityQuestionSaved'))));
    if (widget.change && context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final theme = Theme.of(context);
    return PopScope(
      // Configuration obligatoire : pas de retour possible tant qu'elle n'est pas faite.
      canPop: widget.change,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('securityQuestionTitle')),
          automaticallyImplyLeading: widget.change,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: Spacing.form,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: t(widget.change ? 'changeSecurityQuestion' : 'protectYourAccount'),
                    subtitle: t('securityQuestionExplain'),
                    compact: true,
                  ),
                  const SizedBox(height: 24),
                  SectionCard(
                    child: Row(
                      children: [
                        Icon(Icons.agriculture_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t(SecurityQuestions.translationKey(_questionId)), style: theme.textTheme.titleMedium),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _answerCtrl,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: widget.change ? TextInputAction.next : TextInputAction.done,
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
                  ),
                  if (widget.change) ...[
                    const SizedBox(height: 16),
                    PasswordFormField(
                      controller: _passwordCtrl,
                      label: t('currentPassword'),
                      action: TextInputAction.done,
                      showTooltip: t('showPassword'),
                      hideTooltip: t('hidePassword'),
                      validator: (v) => (v ?? '').isEmpty ? t('errPasswordRequired') : null,
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Text(t('save')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

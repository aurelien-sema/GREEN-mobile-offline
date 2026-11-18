import 'package:flutter/material.dart';

/// En-tête commun des écrans d'accès : logo, titre, sous-titre.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool compact;
  const AuthHeader({super.key, required this.title, this.subtitle, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = compact ? 56.0 : 84.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Image.asset(
            isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_white.png',
            cacheWidth: 256,
            semanticLabel: 'GREEN',
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Champ mot de passe avec bouton afficher / masquer.
class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputAction action;
  final bool isNewPassword;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final String showTooltip;
  final String hideTooltip;

  const PasswordFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.showTooltip,
    required this.hideTooltip,
    this.helper,
    this.validator,
    this.action = TextInputAction.next,
    this.isNewPassword = false,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.action,
      autocorrect: false,
      enableSuggestions: false,
      maxLength: 128,
      autofillHints: [widget.isNewPassword ? AutofillHints.newPassword : AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 2,
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? widget.showTooltip : widget.hideTooltip,
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}

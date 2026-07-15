import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/validation/validators.dart';
import '../../../providers/locale_provider.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_app_bar.dart';

/// Étape courante du flux de réinitialisation.
enum _Step { identify, reset, done }

/// Réinitialisation locale du mot de passe.
///
/// L'application ne dispose d'aucun backend (ni email, ni SMS) : l'authentification
/// est entièrement locale à l'appareil. Un vrai "email de réinitialisation" n'a donc
/// pas de sens ici. Ce flux vérifie que l'identifiant (email ou téléphone) correspond
/// bien à un compte enregistré sur cet appareil, puis permet de définir directement un
/// nouveau mot de passe — plutôt que d'afficher un faux message de succès qui ne mène
/// à aucune récupération réelle.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Step _step = _Step.identify;
  bool _isLoading = false;
  String? _error;
  String? _resolvedIdentifier;

  @override
  void dispose() {
    _identifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleIdentify() async {
    final identifier = _identifierController.text.trim();
    setState(() => _error = null);

    final isEmailLike = identifier.contains('@');
    final validationError = isEmailLike
        ? Validators.validateEmail(identifier)
        : Validators.validatePhone(identifier);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() => _isLoading = true);
    final user = await authService.findUserByIdentifier(identifier);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user == null) {
      setState(() => _error = context.read<LocaleProvider>().t('noAccountFoundForIdentifier'));
      return;
    }

    setState(() {
      _resolvedIdentifier = identifier;
      _step = _Step.reset;
    });
  }

  Future<void> _handleReset() async {
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() => _error = null);

    final validationError = Validators.validatePassword(newPassword);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = context.read<LocaleProvider>().t('passwordsDoNotMatch'));
      return;
    }

    setState(() => _isLoading = true);
    final ok = await authService.resetPasswordForIdentifier(_resolvedIdentifier!, newPassword);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) {
      setState(() => _error = context.read<LocaleProvider>().t('resetFailedMessage'));
      return;
    }
    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LocaleProvider>().t;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: CustomAppBar(
        title: t('resetPasswordTitle'),
        isDarkMode: isDarkMode,
      ),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.1,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: switch (_step) {
              _Step.identify => _buildIdentifyView(context, isDarkMode, t),
              _Step.reset => _buildResetView(context, isDarkMode, t),
              _Step.done => _buildSuccessView(context, isDarkMode, t),
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon, bool isDarkMode) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        borderSide: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }

  Widget _buildErrorText() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
    );
  }

  Widget _buildIdentifyView(BuildContext context, bool isDarkMode, String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.paddingLarge),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkTertiary : AppColors.lightTertiary,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            child: Icon(
              Icons.lock_open_rounded,
              size: 32,
              color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
        ).animate().scale(duration: AppConstants.animationNormal),
        const SizedBox(height: AppConstants.paddingLarge),
        Text(
          t('forgotPasswordTitle'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(duration: AppConstants.animationNormal),
        const SizedBox(height: AppConstants.paddingMedium),
        Text(
          t('offlineResetExplanation'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: _fieldDecoration(t('emailOrPhoneHint'), Icons.person_outline, isDarkMode),
        ),
        _buildErrorText(),
        const SizedBox(height: AppConstants.paddingLarge),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleIdentify,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
              shape: const StadiumBorder(),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(t('continueButton'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t('rememberPasswordQuestion'), style: Theme.of(context).textTheme.bodySmall),
            GestureDetector(
              onTap: () => context.pop(),
              child: Text(
                t('login'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetView(BuildContext context, bool isDarkMode, String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.paddingLarge),
        Text(t('newPasswordTitle'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppConstants.paddingMedium),
        Text(
          t('accountFoundForTemplate').replaceAll('{identifier}', _resolvedIdentifier ?? ''),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          enabled: !_isLoading,
          decoration: _fieldDecoration(t('newPasswordTitle'), Icons.lock_outline, isDarkMode),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          enabled: !_isLoading,
          decoration: _fieldDecoration(t('confirmNewPasswordHint'), Icons.lock_outline, isDarkMode),
        ),
        _buildErrorText(),
        const SizedBox(height: AppConstants.paddingLarge),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
              shape: const StadiumBorder(),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(t('resetButton'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDarkMode, String Function(String) t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
          ),
          child: const Icon(Icons.check_circle, size: 60, color: Colors.white),
        ).animate().scale(duration: AppConstants.animationNormal),
        const SizedBox(height: 32),
        Text(t('passwordResetTitle'), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          t('canNowLoginMessage'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
              shape: const StadiumBorder(),
            ),
            child: Text(t('backToLogin'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

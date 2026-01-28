import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetEmail() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre adresse email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(
        title: 'Réinitialiser le mot de passe',
        isDarkMode: isDarkMode,
      ),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.1,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: _emailSent
                ? _buildSuccessView(context, isDarkMode)
                : _buildFormView(context, isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.paddingLarge),

        // Title
        Text(
              'Mot de passe oublié?',
              style: Theme.of(context).textTheme.headlineSmall,
            )
            .animate()
            .fadeIn(duration: AppConstants.animationNormal)
            .slideX(begin: -20, end: 0),

        const SizedBox(height: AppConstants.paddingMedium),

        // Description
        Text(
              'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 100))
            .slideX(begin: -20, end: 0),

        const SizedBox(height: AppConstants.paddingLarge),

        // Email Field
        TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Adresse email',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: isDarkMode
                    ? const Color.fromRGBO(27, 94, 32, 0.3)
                    : AppColors.lightTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 200))
            .slideY(begin: 20, end: 0),

        const SizedBox(height: AppConstants.paddingLarge),

        // Send Button
        SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Envoyer le lien',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 300))
            .slideY(begin: 20, end: 0),

        const SizedBox(height: AppConstants.paddingMedium),

        // Back to Login
        Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Se souvenir du mot de passe? ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 400))
            .slideY(begin: 20, end: 0),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDarkMode
                ? AppColors.darkGradient
                : AppColors.lightGradient,
          ),
          child: const Icon(Icons.check_circle, size: 60, color: Colors.white),
        ).animate().scale(duration: AppConstants.animationNormal),

        const SizedBox(height: 32),

        Text(
              'Email envoyé!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 100))
            .slideY(begin: 20, end: 0),

        const SizedBox(height: 16),

        Text(
              'Vérifiez votre email pour le lien de réinitialisation du mot de passe.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 200))
            .slideY(begin: 20, end: 0),

        const SizedBox(height: 32),

        SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                  ),
                ),
                child: const Text(
                  'Retour à la connexion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 300))
            .slideY(begin: 20, end: 0),
      ],
    );
  }
}

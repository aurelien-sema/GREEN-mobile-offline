import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../services/auth_service.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/validation/validators.dart';
// password hashing/verification handled by AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _identifierController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final input = _identifierController.text.trim();
    final emailErr = input.contains('@')
        ? Validators.validateEmail(input)
        : Validators.validatePhone(input);
    final passErr = Validators.validatePassword(_passwordController.text);
    if (emailErr != null || passErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailErr ?? passErr ?? '')));
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () async {
      final user = await authService.loginWithIdentifierAndPassword(
        input,
        _passwordController.text,
      );
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identifiants invalides')),
          );
        }
        return;
      }
      if (mounted) {
        // inform provider about authenticated user
        try {
          final authProv = Provider.of<AuthProvider>(context, listen: false);
          authProv.setCurrentUserFromService(user);
        } catch (_) {}
        setState(() => _isLoading = false);
        context.go('/home');
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
      appBar: CustomAppBar(title: 'Connexion', isDarkMode: isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? AppColors.darkGradient
                      : AppColors.lightGradient,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusXLarge,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.eco,
                    size: 80,
                    color: Colors.white,
                  ).animate().scale(duration: AppConstants.animationNormal),
                ),
              ).animate().fadeIn(duration: AppConstants.animationNormal),
              const SizedBox(height: 40),
              Text(
                    'Bienvenue',
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 100))
                  .slideX(begin: -20, end: 0),
              const SizedBox(height: 8),
              Text(
                    'Connectez-vous pour accéder à l\'application',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkHint
                          : AppColors.lightHint,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 150))
                  .slideX(begin: -20, end: 0),
              const SizedBox(height: 32),
              Text(
                'Email ou Téléphone',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      hintText: 'email ou numéro de téléphone',
                      prefixIcon: Icon(
                        Icons.person,
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 24),
              Text(
                'Mot de passe',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 250))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 12),
              // Forgot Password Link
              Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        'Mot de passe oublié?',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          fontSize: AppConstants.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 275))
                  .slideX(begin: 20, end: 0),
              const SizedBox(height: 20),
              GradientButton(
                    label: _isLoading ? 'Connexion...' : 'Se connecter',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 300))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 16),
              Center(
                    child: TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        'Pas de compte ? S\'inscrire',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          fontSize: AppConstants.fontSizeRegular,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 350))
                  .slideY(begin: 10, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

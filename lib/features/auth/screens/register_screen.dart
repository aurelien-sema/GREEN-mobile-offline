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
// password hashing handled by AuthService (PBKDF2)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _usePhone = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final nameErr = Validators.validateName(_nameController.text);
    final emailErr = !_usePhone
        ? Validators.validateEmail(_emailController.text)
        : null;
    final phoneErr = _usePhone
        ? Validators.validatePhone(_phoneController.text)
        : null;
    final passErr = Validators.validatePassword(_passwordController.text);
    if (nameErr != null ||
        emailErr != null ||
        passErr != null ||
        phoneErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nameErr ?? emailErr ?? phoneErr ?? passErr ?? ''),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () async {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final user = UserModel(
        id: id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        passwordHash: '',
      );
      final ok = await authService.registerWithPassword(
        user,
        _passwordController.text,
      );
      if (!ok) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Un compte avec cet email existe déjà'),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      // if registration succeeded, try to fetch stored user and set provider
      try {
        final identifier = _usePhone
            ? _phoneController.text.trim()
            : _emailController.text.trim();
        final stored = authService.getUserByIdentifier(identifier);
        if (stored != null) {
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setCurrentUserFromService(stored);
        }
      } catch (_) {}
      setState(() => _isLoading = false);
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(title: 'Inscription', isDarkMode: isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    'Créer un compte',
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(duration: AppConstants.animationNormal)
                  .slideX(begin: -20, end: 0),
              const SizedBox(height: 8),
              Text(
                    'Rejoignez-nous pour commencer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkHint
                          : AppColors.lightHint,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 100))
                  .slideX(begin: -20, end: 0),
              const SizedBox(height: 32),

              // Registration Method Toggle
              Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _usePhone = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_usePhone
                                    ? (isDarkMode
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMedium,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                    color: !_usePhone
                                        ? Colors.white
                                        : (isDarkMode
                                              ? AppColors.darkOnBackground
                                              : AppColors.lightOnBackground),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _usePhone = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _usePhone
                                    ? (isDarkMode
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMedium,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Téléphone',
                                  style: TextStyle(
                                    color: _usePhone
                                        ? Colors.white
                                        : (isDarkMode
                                              ? AppColors.darkOnBackground
                                              : AppColors.lightOnBackground),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 150))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 24),

              // Name Field
              Text(
                'Nom complet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Jean Dupont',
                      prefixIcon: Icon(
                        Icons.person,
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 24),

              // Email or Phone Field
              Text(
                _usePhone ? 'Numéro de téléphone' : 'Email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                    controller: _usePhone ? _phoneController : _emailController,
                    keyboardType: _usePhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: _usePhone
                          ? '+237 6 12 34 56 78'
                          : 'votre@email.com',
                      prefixIcon: Icon(
                        _usePhone ? Icons.phone : Icons.email,
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 250))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 24),

              // Password Field
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
                  .fadeIn(delay: const Duration(milliseconds: 300))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 24),

              // Confirm Password Field
              Text(
                'Confirmer le mot de passe',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
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
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 350))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 32),

              // Register Button
              GradientButton(
                    label: _isLoading ? 'Inscription...' : 'S\'inscrire',
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 400))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 16),

              // Login Link
              Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Vous avez un compte ? Se connecter',
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
                  .fadeIn(delay: const Duration(milliseconds: 450))
                  .slideY(begin: 10, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

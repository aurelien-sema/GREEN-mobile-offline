import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../services/auth_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/validation/validators.dart';
import '../../../core/utils/text_input_formatters.dart';
import '../../../core/extensions/context_extensions.dart';
// password hashing handled by AuthService (PBKDF2)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _usePhone = true;
  // Numéro complet avec indicatif pays (ex: +237612345678), capturé via
  // IntlPhoneField.onChanged. Utilisé comme identifiant stocké/recherché
  // plutôt que le seul numéro local, pour rester cohérent avec la connexion.
  String _fullPhone = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      context.showSnackBarMessage(nameErr ?? emailErr ?? phoneErr ?? passErr ?? '');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () async {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final phoneToStore = _fullPhone.isNotEmpty ? _fullPhone : _phoneController.text.trim();
      final user = UserModel(
        id: id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _usePhone ? phoneToStore : '',
        passwordHash: '',
      );
      final result = await authService.registerWithPassword(
        user,
        _passwordController.text,
      );
      if (result != RegisterResult.success) {
        if (mounted) {
          setState(() => _isLoading = false);
          final t = context.read<LocaleProvider>().t;
          final message = result == RegisterResult.phoneTaken
              ? t('duplicatePhoneAccount')
              : t('duplicateEmailAccount');
          context.showSnackBarMessage(message);
        }
        return;
      }
      if (!mounted) return;
      // if registration succeeded, try to fetch stored user and set provider
      try {
        final identifier = _usePhone ? phoneToStore : _emailController.text.trim();
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
    final t = context.watch<LocaleProvider>().t;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(title: t('register'), isDarkMode: isDarkMode),
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
                    t('createAccount'),
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(duration: AppConstants.animationNormal)
                  .slideX(begin: -20, end: 0),
              const SizedBox(height: 8),
              Text(
                    t('joinUsToStart'),
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
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightChipNeutralBg,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLarge,
                      ),
                      border: Border.all(
                        color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: !_usePhone,
                            label: t('email'),
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
                                    t('email'),
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
                        ),
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: _usePhone,
                            label: t('phone'),
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
                                    t('phone'),
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
                t('fullName'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [CapitalizeSentencesFormatter()],
                    decoration: InputDecoration(
                      hintText: 'TANKEU Aurélien', // Requested placeholder
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
                _usePhone ? t('phoneNumberLabel') : t('email'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _usePhone
                  ? IntlPhoneField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: '6 12 34 56 78',
                        counterText: '',
                      ),
                      initialCountryCode: 'CM',
                      onChanged: (phone) {
                        _fullPhone = phone.completeNumber;
                      },
                    )
                  : TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'votre@email.com',
                        prefixIcon: Icon(
                          Icons.email,
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
                t('password'),
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
                t('confirmPassword'),
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
                    label: _isLoading ? t('registering') : t('signUpButton'),
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
                        t('haveAccountLogin'),
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

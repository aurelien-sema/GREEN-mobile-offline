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
  bool _isPhone = true; // Default to phone as requested
  // Numéro complet avec indicatif pays, capturé via IntlPhoneField.onChanged —
  // c'est ce qui a été stocké à l'inscription, donc c'est ce qu'il faut
  // rechercher ici plutôt que le seul numéro local du contrôleur.
  String _fullPhone = '';

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
    final rawInput = _identifierController.text.trim();
    // Se base sur le mode réellement sélectionné par l'utilisateur (toggle
    // Téléphone/Email), pas sur le contenu du champ — évite une validation
    // incohérente si le texte et le mode affiché venaient à diverger.
    final identifierErr = _isPhone
        ? Validators.validatePhone(rawInput)
        : Validators.validateEmail(rawInput);
    final passErr = Validators.validatePassword(_passwordController.text);
    if (identifierErr != null || passErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(identifierErr ?? passErr ?? '')));
      return;
    }

    final input = _isPhone
        ? (_fullPhone.isNotEmpty ? _fullPhone : rawInput)
        : rawInput;

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
            SnackBar(content: Text(context.read<LocaleProvider>().t('invalidCredentials'))),
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
    final t = context.watch<LocaleProvider>().t;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(title: t('login'), isDarkMode: isDarkMode),
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
                    t('welcomeSimple'),
                    style: Theme.of(context).textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 100))
                  .slideX(begin: -20, end: 0),
              const SizedBox(height: 8),
              Text(
                    t('loginToAccess'),
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
              const SizedBox(height: 32),
              
              // Toggle Email/Phone
              Center(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(t('phone')),
                      icon: const Icon(Icons.phone),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(t('email')),
                      icon: const Icon(Icons.email),
                    ),
                  ],
                  selected: {_isPhone},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isPhone = newSelection.first;
                      _identifierController.clear();
                      _fullPhone = '';
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary;
                        }
                        return Colors.transparent;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return isDarkMode
                            ? AppColors.darkHint
                            : AppColors.lightHint;
                      },
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: AppConstants.animationNormal),
              const SizedBox(height: 24),

              Text(
                _isPhone ? t('phoneNumberLabel') : t('emailAddressLabel'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _isPhone
                  ? IntlPhoneField(
                      controller: _identifierController,
                      decoration: InputDecoration(
                        hintText: '699 99 99 99',
                        counterText: '',
                      ),
                      initialCountryCode: 'CM', // Default to Cameroon
                      onChanged: (phone) {
                        _fullPhone = phone.completeNumber;
                      },
                    )
                  : TextField(
                      controller: _identifierController,
                      decoration: InputDecoration(
                        hintText: 'exemple@email.com',
                        prefixIcon: Icon(
                          Icons.email,
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
                  .fadeIn(delay: const Duration(milliseconds: 250))
                  .slideY(begin: 10, end: 0),
              const SizedBox(height: 12),
              // Forgot Password Link
              Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        t('forgotPassword'),
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
                    label: _isLoading ? t('loggingIn') : t('loginButton'),
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
                        t('noAccountSignUp'),
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

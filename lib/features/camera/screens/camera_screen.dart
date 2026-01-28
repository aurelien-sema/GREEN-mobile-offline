import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/scan_provider.dart';
import '../../../services/history_service.dart';
import 'package:green_app/models/scan_result_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/animation_effects.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
      _analyzeImage();
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
      _analyzeImage();
    }
  }

  void _analyzeImage() {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);

    final file = File(_selectedImage!.path);

    // Use the ScanProvider which calls the VisionService (remote or mock)
    final scanProvider = context.read<ScanProvider>();

    scanProvider
        .analyzePlantImage(file)
        .then((success) async {
          if (!mounted) return;
          setState(() => _isLoading = false);
          if (success) {
            final ScanResultModel? result = scanProvider.currentScanResult;
            if (result != null) {
              // Persist to local history for offline access
              try {
                await historyService.addScan(result);
              } catch (_) {}
              _showResultsDialog(result);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analyse terminée, aucun résultat disponible.'),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Échec de l\'analyse: ${scanProvider.error ?? 'Erreur inconnue'}',
                ),
              ),
            );
          }
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'analyse: $e')),
          );
        });
  }

  void _showResultsDialog(ScanResultModel result) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    final confidence = (result.confidence).clamp(0.0, 1.0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résultats du scan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maladie détectée:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              result.diseaseName,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Confiance: ${(confidence * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              backgroundColor: isDarkMode
                  ? AppColors.darkTertiary
                  : AppColors.lightTertiary,
              valueColor: AlwaysStoppedAnimation(
                isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Traitement: ${result.treatment}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/chat');
            },
            child: const Text('Consulter l\'IA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    context.read<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(title: 'Scanner', isDarkMode: isDarkMode),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.1,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const SmoothScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Image Preview or Placeholder
                _buildImagePreview(context, isDarkMode)
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal)
                    .slideY(begin: 20, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Instructions Section
                GradientSection(
                      title: 'Instructions',
                      isDarkMode: isDarkMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInstructionItem(
                            '1',
                            'Prenez une photo claire de la plante',
                            isDarkMode,
                          ).slideUpIn(delayMs: 100),
                          const SizedBox(height: 12),
                          _buildInstructionItem(
                            '2',
                            'Assurez-vous d\'avoir une bonne lumière',
                            isDarkMode,
                          ).slideUpIn(delayMs: 150),
                          const SizedBox(height: 12),
                          _buildInstructionItem(
                            '3',
                            'Centrez la plante dans le cadre',
                            isDarkMode,
                          ).slideUpIn(delayMs: 200),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 200))
                    .slideX(begin: -20, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Action Buttons
                Column(
                  children: [
                    _buildActionButton(
                          context: context,
                          icon: Icons.camera_alt,
                          title: 'Prendre une photo',
                          onTap: _pickImageFromCamera,
                          isDarkMode: isDarkMode,
                        )
                        .animate(delay: const Duration(milliseconds: 300))
                        .fadeIn()
                        .slideY(begin: 20, end: 0),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _buildActionButton(
                          context: context,
                          icon: Icons.photo_library,
                          title: 'Sélectionner une photo',
                          onTap: _pickImageFromGallery,
                          isDarkMode: isDarkMode,
                        )
                        .animate(delay: const Duration(milliseconds: 350))
                        .fadeIn()
                        .slideY(begin: 20, end: 0),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, bool isDarkMode) {
    return GradientCard(
      isDarkMode: isDarkMode,
      opacity: 0.1,
      borderRadius: AppConstants.radiusXLarge,
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_search,
                    size: 80,
                    color: isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sélectionnez une image',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prenez une photo ou choisissez-en une dans votre galerie',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkHint
                          : AppColors.lightHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? AppColors.darkGradient
                : AppColors.lightGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: BounceAnimation(
        child: GradientCard(
          isDarkMode: isDarkMode,
          opacity: 0.15,
          borderRadius: AppConstants.radiusMedium,
          onTap: _isLoading ? null : onTap,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? AppColors.darkGradient
                      : AppColors.lightGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      _isLoading ? 'Analyse...' : 'Appuyez pour sélectionner',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode
                            ? AppColors.darkHint
                            : AppColors.lightHint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

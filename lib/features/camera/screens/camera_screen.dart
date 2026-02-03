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
import 'field_sheet_screen.dart';

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
              if (result.diseaseId == 'unknown') {
                _showUnknownImageDialog();
              } else {
                // Persist to local history for offline access
                try {
                  await historyService.addScan(result);
                } catch (_) {}
                // Naviguer vers la fiche terrain (offline) au lieu d'une pop-up
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => FieldSheetScreen(scanResult: result),
                  ),
                );
              }
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

  // Résultats d'analyse: affichage remplacé par la Fiche terrain (FieldSheetScreen) pour être entièrement offline et plus conviviale.
  void _showUnknownImageDialog() {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.help_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Image non reconnue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Désolé, l'analyse n'est pas parvenue à identifier une plante ou une maladie connue. "
              "Assurez-vous que l'image est bien éclairée et que la plante est centrée.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Il est possible que cette plante ne soit pas encore répertoriée dans notre base de données.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _selectedImage = null);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  // Ancienne méthode d'affichage des résultats supprimée — la Fiche terrain couvre ces informations maintenant.
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    context.read<ThemeProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: CustomAppBar(
          title: 'Scanner',
          isDarkMode: isDarkMode,
          showProfileIcon: true,
        ),
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
                // Consulter les maladies button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => context.go('/diseases'),
                    icon: Icon(
                      Icons.local_hospital,
                      size: 18,
                      color: isDarkMode
                          ? AppColors.darkSecondary
                          : AppColors.lightPrimary,
                    ),
                    label: Text(
                      'Consulter les maladies',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? AppColors.darkSecondary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 400))
                    .fadeIn()
                    .slideY(begin: 20, end: 0),
              ],
            ),
          ),
        ),
      ),
    ));
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

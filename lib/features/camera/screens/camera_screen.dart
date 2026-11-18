import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/green_web/photo_sync_service.dart';
import '../../../services/history_service.dart';
import '../../../services/vision_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../shared/widgets/custom_app_bar.dart';

/// Scanner : photo (appareil ou galerie) → analyse hors ligne → fiche terrain.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _analysing = false;

  Future<void> _pick(ImageSource source) async {
    final t = context.read<LocaleProvider>().t;
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
        requestFullMetadata: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('cameraUnavailable'))));
      return;
    }
    if (picked == null || !mounted) return;
    setState(() => _image = File(picked!.path));
    await _analyse(source == ImageSource.camera ? 'camera' : 'gallery');
  }

  Future<void> _analyse(String source) async {
    final image = _image;
    if (image == null) return;
    final t = context.read<LocaleProvider>().t;
    final catalog = context.read<DiseasesProvider>();
    final sync = context.read<PhotoSyncService>();
    setState(() => _analysing = true);
    try {
      var result = await visionService.analyze(image, catalog: catalog, source: source);
      await historyService.addScan(result);
      result = await sync.enqueue(result);
      if (!mounted) return;
      setState(() {
        _analysing = false;
        _image = null;
      });
      if (result.isError) {
        _showError();
      } else {
        context.push('/scan/${result.id}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _analysing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('analysisError'))));
    }
  }

  void _showError() {
    final t = context.read<LocaleProvider>().t;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.image_not_supported_outlined),
        title: Text(t('imageNotRecognized')),
        content: Text(t('imageNotRecognizedExplanation')),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t('understood')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: t('scanner'), showProfileIcon: true),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(Spacing.gutter, Spacing.md, Spacing.gutter, Spacing.xxxl),
            children: [
              Text(t('scanIntro'), style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              _BigAction(
                icon: Icons.photo_camera_rounded,
                title: t('takePicture'),
                caption: t('takePictureCaption'),
                filled: true,
                onTap: _analysing ? null : () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _BigAction(
                icon: Icons.photo_library_rounded,
                title: t('selectPicture'),
                caption: t('selectPictureCaption'),
                onTap: _analysing ? null : () => _pick(ImageSource.gallery),
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: t('goodPhotoTips'),
                child: BulletList(
                  icon: Icons.check_rounded,
                  items: [t('instructionStep1'), t('instructionStep2'), t('instructionStep3')],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t('supportedCropsNote'))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push('/diseases'),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(t('viewDiseases')),
              ),
            ],
          ),
          if (_analysing) _AnalysingOverlay(image: _image, label: t('analyzingShort')),
        ],
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final bool filled;
  final VoidCallback? onTap;
  const _BigAction({required this.icon, required this.title, required this.caption, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = filled ? scheme.primary : scheme.surface;
    final fg = filled ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: filled ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 36, color: filled ? fg : scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(color: fg)),
                    const SizedBox(height: 2),
                    Text(caption, style: theme.textTheme.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysingOverlay extends StatelessWidget {
  final File? image;
  final String label;
  const _AnalysingOverlay({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(image!, width: 220, height: 220, fit: BoxFit.cover, cacheWidth: 600),
                  ),
                const SizedBox(height: 24),
                const SizedBox(width: 220, child: LinearProgressIndicator()),
                const SizedBox(height: 12),
                Semantics(liveRegion: true, child: Text(label, style: theme.textTheme.titleMedium)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Photo de profil : l'image choisie est recadrée puis COPIÉE dans le dossier
/// privé de l'application (`avatars/`). Cette copie est conservée tant que
/// l'utilisateur ne la supprime pas, même si l'original est effacé de la
/// galerie, et même après une déconnexion.
class ProfileImageService {
  final ImagePicker _picker = ImagePicker();

  Future<Directory> _dir() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/avatars');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Renvoie le chemin de la nouvelle copie, ou null si l'utilisateur annule.
  Future<String?> pickAndStore({
    required ImageSource source,
    required String userId,
    required String cropTitle,
    required Color toolbarColor,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return null;

    String path = picked.path;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        maxWidth: 600,
        maxHeight: 600,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: toolbarColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(title: cropTitle, aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return null; // recadrage annulé
      path = cropped.path;
    } catch (e) {
      // Recadreur natif indisponible : on garde l'image (déjà réduite).
      debugPrint('Recadrage impossible, image conservée sans recadrage : $e');
    }

    final dir = await _dir();
    // Nom horodaté : force le rafraîchissement du cache d'images de Flutter.
    final target = File('${dir.path}/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(path).copy(target.path);
    return target.path;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Suppression de la photo de profil impossible : $e');
    }
  }
}

final profileImageService = ProfileImageService();

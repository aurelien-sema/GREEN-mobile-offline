import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../user_scope.dart';

/// Photos des analyses : copie permanente dans le dossier privé de
/// l'application (`scans/<compte>/`), avec une miniature pour l'historique.
///
/// Avant la v2, l'historique gardait le chemin du fichier temporaire du
/// sélecteur d'images : Android le supprime tôt ou tard, et les photos de
/// l'historique et des fiches terrain disparaissaient.
class ScanImageStore {
  static const int maxSide = 1600;
  static const int thumbSide = 320;

  final Future<Directory> Function() _baseDir;
  ScanImageStore({Future<Directory> Function()? baseDir})
      : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  Future<Directory> _dirFor(String? userId) async {
    final dir = Directory('${(await _baseDir()).path}/scans/${userId ?? 'guest'}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copie [source] (photo ou image de la galerie) : JPEG orienté, 1600 px
  /// au plus sur le grand côté, sans métadonnées EXIF (position GPS
  /// comprise), plus une miniature. Renvoie (photo, miniature).
  Future<(String, String)> persist(File source, String scanId) async {
    final dir = await _dirFor(UserScope.userId);
    final bytes = await source.readAsBytes();
    final encoded = await Isolate.run(() => _encode(bytes));
    final photo = File('${dir.path}/$scanId.jpg');
    final thumb = File('${dir.path}/${scanId}_thumb.jpg');
    if (encoded == null) {
      // Format non décodable ici : copie brute, sans miniature.
      await source.copy(photo.path);
      return (photo.path, photo.path);
    }
    await photo.writeAsBytes(encoded.$1, flush: true);
    await thumb.writeAsBytes(encoded.$2, flush: true);
    return (photo.path, thumb.path);
  }

  Future<void> delete(String? photoPath, String? thumbPath) async {
    for (final p in {photoPath, thumbPath}) {
      if (p == null || p.isEmpty) continue;
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// Supprime toutes les photos d'un compte (suppression du compte).
  Future<void> deleteAllFor(String userId) async {
    final dir = Directory('${(await _baseDir()).path}/scans/$userId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static (Uint8List, Uint8List)? _encode(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final oriented = img.bakeOrientation(decoded);
    final rgb = oriented.numChannels == 3 && oriented.format == img.Format.uint8
        ? oriented
        : oriented.convert(format: img.Format.uint8, numChannels: 3);
    img.Image fit(img.Image src, int side) {
      if (src.width <= side && src.height <= side) return src;
      return src.width >= src.height
          ? img.copyResize(src, width: side, interpolation: img.Interpolation.average)
          : img.copyResize(src, height: side, interpolation: img.Interpolation.average);
    }

    final full = fit(rgb, maxSide)..exif.clear();
    final small = fit(rgb, thumbSide)..exif.clear();
    return (img.encodeJpg(full, quality: 85), img.encodeJpg(small, quality: 75));
  }
}

final scanImageStore = ScanImageStore();

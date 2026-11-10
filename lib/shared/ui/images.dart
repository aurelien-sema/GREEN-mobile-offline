import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/user_model.dart';

/// Photo de profil (copie locale) ou initiales.
class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  const UserAvatar({super.key, required this.user, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = user?.avatarPath;
    final file = path == null ? null : File(path);
    final hasPhoto = file != null && file.existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: hasPhoto ? FileImage(file) : null,
      child: Text(
        user?.initials ?? '?',
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

/// Image locale d'une analyse, avec repli si le fichier a disparu.
class LocalImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final int? cacheWidth;

  const LocalImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
    );
    final p = path;
    if (p == null || p.isEmpty || !File(p).existsSync()) {
      return ClipRRect(borderRadius: borderRadius, child: placeholder);
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        File(p),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

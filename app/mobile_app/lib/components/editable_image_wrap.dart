import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../ui/app_theme.dart';

class EditableImageWrap extends StatelessWidget {
  const EditableImageWrap({
    super.key,
    this.existingImages = const [],
    this.localImages = const [],
    this.onRemoveExisting,
    this.onRemoveLocal,
    this.tileSize = 72,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final List<String> existingImages;
  final List<XFile> localImages;
  final ValueChanged<int>? onRemoveExisting;
  final ValueChanged<int>? onRemoveLocal;
  final double tileSize;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (existingImages.isEmpty && localImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (var i = 0; i < existingImages.length; i++)
          _EditableImageTile(
            size: tileSize,
            image: Image.network(existingImages[i], fit: BoxFit.cover),
            onRemove: onRemoveExisting == null
                ? null
                : () => onRemoveExisting!(i),
          ),
        for (var i = 0; i < localImages.length; i++)
          _EditableImageTile(
            size: tileSize,
            image: Image.file(File(localImages[i].path), fit: BoxFit.cover),
            onRemove: onRemoveLocal == null ? null : () => onRemoveLocal!(i),
          ),
      ],
    );
  }
}

class _EditableImageTile extends StatelessWidget {
  const _EditableImageTile({
    required this.size,
    required this.image,
    this.onRemove,
  });

  final double size;
  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(width: size, height: size, child: image),
        ),
        if (onRemove != null)
          Positioned(
            right: -8,
            top: -8,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: AppColors.destructive,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }
}

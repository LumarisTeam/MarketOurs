import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:image_picker/image_picker.dart';

import '../components/app_network_image.dart';
import '../ui/app_theme.dart';

/// Represents a single image in the editable list, which may be either
/// an already-uploaded remote URL or a locally picked file.
class EditableImageEntry {
  const EditableImageEntry({
    required this.id,
    required this.displayUrl,
    this.isExisting = false,
    this.remoteUrl,
    this.localFile,
  });

  /// Stable unique key suitable for [ReorderableListView] keys.
  final Key id;

  /// URL or file path used to display the thumbnail.
  final String displayUrl;

  /// Whether this image already exists on the server.
  final bool isExisting;

  /// The remote URL (only valid when [isExisting] is true).
  final String? remoteUrl;

  /// The local file (only valid when [isExisting] is false).
  final XFile? localFile;
}

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
    // Reorderable mode
    this.reorderable = false,
    this.entries,
    this.onReorder,
    this.onRemoveEntry,
  });

  // --- Legacy mode (non-reorderable) ---

  final List<String> existingImages;
  final List<XFile> localImages;
  final ValueChanged<int>? onRemoveExisting;
  final ValueChanged<int>? onRemoveLocal;
  final double tileSize;
  final double spacing;
  final double runSpacing;

  // --- Reorderable mode ---

  /// When true, uses [entries] + [onReorder] + [onRemoveEntry] instead of
  /// the legacy separate existing/local lists.
  final bool reorderable;

  /// Unified image list used in reorderable mode.
  final List<EditableImageEntry>? entries;

  /// Called with the old and new index after a drag (reorderable mode).
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Called when the remove button on an entry is tapped (reorderable mode).
  /// The parameter is the string representation of the entry's [Key].
  final ValueChanged<String>? onRemoveEntry;

  @override
  Widget build(BuildContext context) {
    if (reorderable) {
      return _buildReorderable(context);
    }
    return _buildWrap();
  }

  Widget _buildWrap() {
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
            image: AppNetworkImage(
              url: existingImages[i],
              width: tileSize,
              height: tileSize,
              fit: BoxFit.cover,
            ),
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

  Widget _buildReorderable(BuildContext context) {
    final items = entries;
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use Wrap with LongPressDraggable + DragTarget for a grid-like reorderable
    // that doesn't overflow horizontally. ReorderableListView with
    // Axis.horizontal + shrinkWrap overflows when images exceed screen width.
    return _ReorderableImageGrid(
      entries: items,
      tileSize: tileSize,
      spacing: spacing,
      onReorder: onReorder!,
      onRemoveEntry: onRemoveEntry,
    );
  }
}

/// A reorderable image grid that uses [Wrap] layout with
/// [LongPressDraggable] / [DragTarget] for drag-to-reorder.
/// This avoids the horizontal overflow issues of [ReorderableListView]
/// while preserving the compact grid appearance.
class _ReorderableImageGrid extends StatefulWidget {
  const _ReorderableImageGrid({
    required this.entries,
    required this.tileSize,
    required this.spacing,
    required this.onReorder,
    this.onRemoveEntry,
  });

  final List<EditableImageEntry> entries;
  final double tileSize;
  final double spacing;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String>? onRemoveEntry;

  @override
  State<_ReorderableImageGrid> createState() => _ReorderableImageGridState();
}

class _ReorderableImageGridState extends State<_ReorderableImageGrid> {
  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final showHandles = entries.length > 1;

    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final tile = _EditableImageTile(
          size: widget.tileSize,
          image: entry.isExisting
              ? AppNetworkImage(
                url: entry.displayUrl,
                width: widget.tileSize,
                height: widget.tileSize,
                fit: BoxFit.cover,
              )
              : Image.file(File(entry.localFile!.path), fit: BoxFit.cover),
          onRemove: widget.onRemoveEntry == null
              ? null
              : () => widget.onRemoveEntry!(entry.id.toString()),
        );

        if (!showHandles) return tile;

        return LongPressDraggable<int>(
          data: index,
          delay: const Duration(milliseconds: 200),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.85,
              child: SizedBox(
                width: widget.tileSize,
                height: widget.tileSize,
                child: tile,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: SizedBox(
              width: widget.tileSize,
              height: widget.tileSize,
              child: tile,
            ),
          ),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              final from = details.data;
              if (from != index) {
                widget.onReorder(from, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: isHighlighted
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: tile,
              );
            },
          ),
        );
      }),
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
        // Remove button — top-right corner
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

import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:material_ui/material_ui.dart' show Colors, Material;
import 'package:image_picker/image_picker.dart';

import 'app_network_image.dart';

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
      // May be null while a submit is in flight; the grid then renders static.
      onReorder: onReorder,
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
    this.onReorder,
    this.onRemoveEntry,
  });

  final List<EditableImageEntry> entries;
  final double tileSize;
  final double spacing;

  /// Null disables drag-to-reorder (e.g. while a submission is in flight).
  final void Function(int oldIndex, int newIndex)? onReorder;
  final ValueChanged<String>? onRemoveEntry;

  @override
  State<_ReorderableImageGrid> createState() => _ReorderableImageGridState();
}

class _ReorderableImageGridState extends State<_ReorderableImageGrid> {
  Widget _buildEntryImage(BuildContext context, EditableImageEntry entry) {
    if (entry.isExisting) {
      return AppNetworkImage(
        url: entry.displayUrl,
        width: widget.tileSize,
        height: widget.tileSize,
        fit: BoxFit.cover,
      );
    }

    final localFile = entry.localFile;
    if (localFile == null) {
      // Defensive: a malformed entry must not take down the whole grid.
      return Container(
        color: context.mc.secondary,
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.photo,
          size: 24,
          color: context.mc.secondaryLabel,
        ),
      );
    }

    return Image.file(File(localFile.path), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final onReorder = widget.onReorder;

    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final tile = _EditableImageTile(
          size: widget.tileSize,
          image: _buildEntryImage(context, entry),
          onRemove: widget.onRemoveEntry == null
              ? null
              : () => widget.onRemoveEntry!(entry.id.toString()),
        );

        // Reordering is disabled when the callback is null (e.g. while a post
        // or comment is being submitted) or when there is nothing to reorder.
        if (onReorder == null || entries.length <= 1) return tile;

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
                onReorder(from, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(McRadii.md),
                  border: isHighlighted
                      ? Border.all(color: context.mc.primary, width: 2)
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
          borderRadius: BorderRadius.circular(McRadii.md),
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
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                color: context.mc.destructive,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luamris_ui/luamris_ui.dart';

import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/utils/dto_validation.dart';

import 'editable_image_wrap.dart';
import '../models/post.dart';
import 'post_tag_selector.dart';

enum PostEditorLayout { page, sheet }

class PostEditorForm extends StatelessWidget {
  const PostEditorForm({
    super.key,
    required this.layout,
    required this.titleController,
    required this.contentController,
    required this.selectedTag,
    required this.existingImages,
    required this.localImages,
    required this.submitLabel,
    required this.onSubmit,
    this.headerText,
    this.titleValidator,
    this.contentValidator,
    this.onPickTag,
    this.onPickImages,
    this.onRemoveExistingImage,
    this.onRemoveLocalImage,
    this.uploadProgress,
    required this.tagEmptyText,
    this.isSubmitting = false,
    // Reorderable mode
    this.reorderableEntries,
    this.onReorderImages,
    this.onRemoveImageEntry,
  });

  final PostEditorLayout layout;
  final String? headerText;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final FormFieldValidator<String>? titleValidator;
  final FormFieldValidator<String>? contentValidator;
  final PostTagDto? selectedTag;
  final List<String> existingImages;
  final List<XFile> localImages;
  final VoidCallback? onPickTag;
  final VoidCallback? onPickImages;
  final ValueChanged<int>? onRemoveExistingImage;
  final ValueChanged<int>? onRemoveLocalImage;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final double? uploadProgress;
  final String tagEmptyText;
  final bool isSubmitting;

  // Reorderable mode
  final List<EditableImageEntry>? reorderableEntries;
  final void Function(int oldIndex, int newIndex)? onReorderImages;
  final ValueChanged<String>? onRemoveImageEntry;

  @override
  Widget build(BuildContext context) {
    if (layout == PostEditorLayout.page) {
      return _buildComposerPage(context);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerText != null) ...[
            Text(headerText!, style: context.mc.textSection),
            const SizedBox(height: 16),
          ],
          _buildEditorCard(context),
          const SizedBox(height: 12),
          _buildImageCard(context),
          const SizedBox(height: 12),
          _buildTagCard(context),
          if (uploadProgress != null) ...[
            const SizedBox(height: 12),
            _buildUploadProgress(context),
          ],
          const SizedBox(height: 20),
          McButton.primary(onPressed: onSubmit, child: Text(submitLabel)),
        ],
      ),
    );
  }

  Widget _buildComposerPage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = context.mc.secondaryLabel;
    final hasImages = reorderableEntries != null
        ? reorderableEntries!.isNotEmpty
        : existingImages.isNotEmpty || localImages.isNotEmpty;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  CupertinoTextFormFieldRow(
                    controller: titleController,
                    padding: EdgeInsets.zero,
                    enabled: !isSubmitting,
                    placeholder: l10n.postCreateTitle,
                    placeholderStyle: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: muted.withValues(alpha: 0.65),
                    ),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: context.mc.label,
                    ),
                    maxLength: DtoLimits.postTitleMax,
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                    validator: titleValidator,
                  ),
                  const SizedBox(height: 14),
                  CupertinoTextFormFieldRow(
                    controller: contentController,
                    padding: EdgeInsets.zero,
                    enabled: !isSubmitting,
                    placeholder: l10n.postCreateContent,
                    placeholderStyle: TextStyle(
                      fontSize: 17,
                      height: 1.7,
                      color: muted.withValues(alpha: 0.65),
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.7,
                      color: context.mc.label,
                    ),
                    minLines: 5,
                    maxLines: null,
                    maxLength: DtoLimits.postContentMax,
                    keyboardType: TextInputType.multiline,
                    validator: contentValidator,
                  ),
                  const SizedBox(height: 24),
                  if (hasImages) ...[
                    EditableImageWrap(
                      existingImages: existingImages,
                      localImages: localImages,
                      onRemoveExisting: onRemoveExistingImage,
                      onRemoveLocal: onRemoveLocalImage,
                      reorderable: reorderableEntries != null,
                      entries: reorderableEntries,
                      onReorder: onReorderImages,
                      onRemoveEntry: onRemoveImageEntry,
                      tileSize: 96,
                      spacing: 12,
                      runSpacing: 12,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onPickImages,
                      child: Container(
                        width: 120,
                        height: 144,
                        decoration: BoxDecoration(
                          color: context.mc.secondary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.plus,
                              size: 30,
                              color: muted.withValues(alpha: 0.65),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.postCreateAddImages,
                              style: TextStyle(fontSize: 14, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 0.5,
                    color: context.mc.separator.withValues(alpha: 0.35),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 4,
                    ),
                    onPressed: onPickTag,
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.tag, size: 21, color: muted),
                        const SizedBox(width: 12),
                        Text(
                          l10n.postCreateTag,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.mc.label,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            selectedTag?.name ?? tagEmptyText,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: muted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (uploadProgress != null) ...[
                    _buildUploadProgress(context),
                    const SizedBox(height: 12),
                  ],
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    color: context.mc.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    onPressed: onSubmit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSubmitting)
                          const CupertinoActivityIndicator()
                        else
                          Icon(
                            CupertinoIcons.paperplane_fill,
                            size: 20,
                            color: context.mc.primary,
                          ),
                        const SizedBox(width: 10),
                        Text(
                          submitLabel,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: context.mc.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context) {
    const contentMaxLines = 6;

    return McCard.elevated(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          McField.text(
            controller: titleController,
            placeholder: AppLocalizations.of(context).postCreateTitle,
            maxLength: DtoLimits.postTitleMax,
            validator: titleValidator,
          ),
          const SizedBox(height: 16),
          McField.text(
            controller: contentController,
            placeholder: AppLocalizations.of(context).postCreateContent,
            maxLines: contentMaxLines,
            maxLength: DtoLimits.postContentMax,
            validator: contentValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    final useReorderable = reorderableEntries != null;
    final hasImages = useReorderable
        ? reorderableEntries!.isNotEmpty
        : (existingImages.isNotEmpty || localImages.isNotEmpty);

    return McCard.elevated(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).postCreateImages,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onPickImages,
                child: Text(
                  AppLocalizations.of(context).postCreateAddImages,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasImages)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.mc.secondary,
                borderRadius: BorderRadius.circular(McRadii.md),
              ),
              child: Text(
                AppLocalizations.of(context).postCreateNoImages,
                style: TextStyle(color: context.mc.secondaryLabel),
              ),
            )
          else if (useReorderable)
            EditableImageWrap(
              reorderable: true,
              entries: reorderableEntries,
              onReorder: onReorderImages,
              onRemoveEntry: onRemoveImageEntry,
              tileSize: 90,
              spacing: 12,
            )
          else
            EditableImageWrap(
              existingImages: existingImages,
              localImages: localImages,
              onRemoveExisting: onRemoveExistingImage,
              onRemoveLocal: onRemoveLocalImage,
              tileSize: 90,
              spacing: 12,
              runSpacing: 12,
            ),
        ],
      ),
    );
  }

  Widget _buildTagCard(BuildContext context) {
    return PostTagSelectorCard(
      tag: selectedTag,
      onPressed: onPickTag,
      enabled: onPickTag != null,
      emptyText: tagEmptyText,
      label: AppLocalizations.of(context).postCreateTag,
    );
  }

  Widget _buildUploadProgress(BuildContext context) {
    final fraction = uploadProgress ?? 0;
    final percent = (fraction * 100).round();
    return McCard.elevated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).postUploading,
                style: TextStyle(
                  fontSize: 14,
                  color: context.mc.secondaryLabel,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(McRadii.sm),
            child: Container(
              height: 6,
              color: context.mc.secondary,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 6, color: context.mc.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

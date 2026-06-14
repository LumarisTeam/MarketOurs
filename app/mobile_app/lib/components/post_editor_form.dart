import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/utils/dto_validation.dart';

import '../models/post.dart';
import '../ui/app_fields.dart';
import '../ui/app_responsive.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';
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
    this.tagEmptyText = '无标签',
    this.isSubmitting = false,
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

  @override
  Widget build(BuildContext context) {
    if (layout == PostEditorLayout.page) {
      return AppResponsiveCenter(
        maxWidth: AppResponsive.formMaxWidth(context),
        padding: AppResponsive.pagePadding(context, narrow: 20),
        child: AppTwoPane(
          primary: _buildEditorCard(context),
          secondary: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageCard(context),
              const SizedBox(height: 12),
              _buildTagCard(),
              if (uploadProgress != null) ...[
                const SizedBox(height: 12),
                _buildUploadProgress(),
              ],
              const SizedBox(height: 20),
              AppPrimaryButton(onPressed: onSubmit, child: Text(submitLabel)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerText != null) ...[
            Text(headerText!, style: AppTextStyles.sectionTitle(context)),
            const SizedBox(height: 16),
          ],
          _buildEditorCard(context),
          const SizedBox(height: 12),
          _buildImageCard(context),
          const SizedBox(height: 12),
          _buildTagCard(),
          if (uploadProgress != null) ...[
            const SizedBox(height: 12),
            _buildUploadProgress(),
          ],
          const SizedBox(height: 20),
          AppPrimaryButton(onPressed: onSubmit, child: Text(submitLabel)),
        ],
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context) {
    final contentMaxLines = layout == PostEditorLayout.page
        ? (AppResponsive.isDesktop(context) ? 12 : 8)
        : 6;

    return AppTappableCard(
      padding: const EdgeInsets.all(20),
      radius: AppRadii.lg,
      child: Column(
        children: [
          AppTextField(
            controller: titleController,
            placeholder: '帖子标题',
            maxLength: DtoLimits.postTitleMax,
            validator: titleValidator,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: contentController,
            placeholder: '分享此刻的新鲜事...',
            maxLines: contentMaxLines,
            maxLength: DtoLimits.postContentMax,
            validator: contentValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    final hasImages = existingImages.isNotEmpty || localImages.isNotEmpty;

    return AppTappableCard(
      padding: const EdgeInsets.all(20),
      radius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '图片',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onPickImages,
                child: const Text(
                  '添加图片',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Text(
                '还没选择图片',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < existingImages.length; i++)
                  _PostEditorImageTile(
                    image: Image.network(existingImages[i], fit: BoxFit.cover),
                    onRemove: onRemoveExistingImage == null
                        ? null
                        : () => onRemoveExistingImage!(i),
                  ),
                for (var i = 0; i < localImages.length; i++)
                  _PostEditorImageTile(
                    image: Image.file(File(localImages[i].path), fit: BoxFit.cover),
                    onRemove: onRemoveLocalImage == null
                        ? null
                        : () => onRemoveLocalImage!(i),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTagCard() {
    return PostTagSelectorCard(
      tag: selectedTag,
      onPressed: onPickTag,
      enabled: onPickTag != null,
      emptyText: tagEmptyText,
    );
  }

  Widget _buildUploadProgress() {
    final fraction = uploadProgress ?? 0;
    final percent = (fraction * 100).round();
    return AppTappableCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      radius: AppRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '正在上传图片',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
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
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Container(
              height: 6,
              color: AppColors.secondary,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 6, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostEditorImageTile extends StatelessWidget {
  const _PostEditorImageTile({required this.image, this.onRemove});

  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(width: 90, height: 90, child: image),
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

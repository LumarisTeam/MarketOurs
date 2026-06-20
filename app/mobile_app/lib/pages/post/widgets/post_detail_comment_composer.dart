import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../components/editable_image_wrap.dart';
import '../../../ui/app_responsive.dart';
import '../../../ui/app_theme.dart';
import '../../../utils/dto_validation.dart';

class PostDetailCommentComposer extends StatelessWidget {
  const PostDetailCommentComposer({
    super.key,
    required this.controller,
    required this.localImages,
    required this.isWorking,
    required this.uploadProgress,
    required this.onPickImages,
    required this.onRemoveLocal,
    required this.onSubmit,
    // Reorderable mode
    this.reorderableEntries,
    this.onReorderImages,
    this.onRemoveImageEntry,
  });

  final TextEditingController controller;
  final List<dynamic> localImages;
  final bool isWorking;
  final double? uploadProgress;
  final VoidCallback? onPickImages;
  final ValueChanged<int> onRemoveLocal;
  final VoidCallback onSubmit;

  // Reorderable mode
  final List<EditableImageEntry>? reorderableEntries;
  final void Function(int oldIndex, int newIndex)? onReorderImages;
  final ValueChanged<String>? onRemoveImageEntry;

  @override
  Widget build(BuildContext context) {
    final useReorderable = reorderableEntries != null;
    final hasImages = useReorderable
        ? reorderableEntries!.isNotEmpty
        : localImages.isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppResponsive.readableMaxWidth(context, fallback: 820),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  AppColors.background,
                  context,
                ).withValues(alpha: 0.8),
                border: Border.all(
                  color: CupertinoDynamicColor.resolve(
                    AppColors.border,
                    context,
                  ).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (useReorderable)
                    EditableImageWrap(
                      reorderable: true,
                      entries: reorderableEntries,
                      onReorder: onReorderImages,
                      onRemoveEntry: onRemoveImageEntry,
                      tileSize: 72,
                    )
                  else
                    EditableImageWrap(
                      localImages: localImages.cast(),
                      onRemoveLocal: onRemoveLocal,
                      tileSize: 72,
                    ),
                  if (hasImages) const SizedBox(height: 10),
                  if (uploadProgress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Container(
                        height: 5,
                        color: AppColors.secondary,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: uploadProgress!.clamp(0.0, 1.0),
                          child: Container(height: 5, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: onPickImages,
                        child: const Icon(CupertinoIcons.photo, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: CupertinoDynamicColor.resolve(
                              AppColors.secondary,
                              context,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: CupertinoTextField(
                            controller: controller,
                            placeholder: AppLocalizations.of(context).postWriteComment,
                            placeholderStyle: TextStyle(
                              fontSize: 14,
                              color: CupertinoDynamicColor.resolve(
                                AppColors.mutedForeground,
                                context,
                              ),
                            ),
                            decoration: null,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoDynamicColor.resolve(
                                AppColors.foreground,
                                context,
                              ),
                            ),
                            cursorColor: AppColors.primary,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                DtoLimits.commentContentMax,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isWorking ? null : onSubmit,
                        child: Text(
                          AppLocalizations.of(context).postCreatePublish,
                          style: TextStyle(
                            color: AppColors.primary.withValues(
                              alpha: isWorking ? 0.5 : 1.0,
                            ),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

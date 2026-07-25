import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../components/editable_image_wrap.dart';
import '../../../ui/app_responsive.dart';
import '../../../ui/app_theme.dart';
import '../../../utils/dto_validation.dart';

class PostDetailCommentComposer extends StatefulWidget {
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
  State<PostDetailCommentComposer> createState() =>
      _PostDetailCommentComposerState();
}

class _PostDetailCommentComposerState extends State<PostDetailCommentComposer> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final hasImages =
        widget.reorderableEntries?.isNotEmpty ?? widget.localImages.isNotEmpty;
    if (widget.isWorking || (!hasText && !hasImages)) {
      return;
    }
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final useReorderable = widget.reorderableEntries != null;
    final hasImages = useReorderable
        ? widget.reorderableEntries!.isNotEmpty
        : widget.localImages.isNotEmpty;

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
                ).withValues(alpha: 0.82),
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
                      entries: widget.reorderableEntries,
                      onReorder: widget.onReorderImages,
                      onRemoveEntry: widget.onRemoveImageEntry,
                      tileSize: 72,
                    )
                  else
                    EditableImageWrap(
                      localImages: widget.localImages.cast(),
                      onRemoveLocal: widget.onRemoveLocal,
                      tileSize: 72,
                    ),
                  if (hasImages) const SizedBox(height: 10),
                  if (widget.uploadProgress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Container(
                        height: 5,
                        color: AppColors.secondary,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: widget.uploadProgress!.clamp(0.0, 1.0),
                          child: Container(height: 5, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CupertinoDynamicColor.resolve(
                            AppColors.secondary,
                            context,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: widget.onPickImages,
                          child: Icon(
                            CupertinoIcons.add,
                            size: 20,
                            color:
                                CupertinoDynamicColor.resolve(
                                  AppColors.foreground,
                                  context,
                                ).withValues(
                                  alpha: widget.onPickImages == null
                                      ? 0.35
                                      : 0.85,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          constraints: const BoxConstraints(minHeight: 44),
                          decoration: BoxDecoration(
                            color: CupertinoDynamicColor.resolve(
                              AppColors.secondary,
                              context,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(
                              color:
                                  CupertinoDynamicColor.resolve(
                                    _focusNode.hasFocus
                                        ? AppColors.primary
                                        : AppColors.border,
                                    context,
                                  ).withValues(
                                    alpha: _focusNode.hasFocus ? 0.35 : 0.45,
                                  ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  controller: widget.controller,
                                  focusNode: _focusNode,
                                  placeholder: AppLocalizations.of(
                                    context,
                                  ).postWriteComment,
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
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _handleSubmit(),
                                  cursorColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      DtoLimits.commentContentMax,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                CupertinoIcons.smiley,
                                size: 20,
                                color: CupertinoDynamicColor.resolve(
                                  AppColors.mutedForeground,
                                  context,
                                ),
                              ),
                            ],
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

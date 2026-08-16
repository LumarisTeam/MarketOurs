import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../components/editable_image_wrap.dart';
import '../../../ui/app_responsive.dart';
import '../../../ui/app_theme.dart';
import '../../../utils/dto_validation.dart';

const List<String> _commentComposerEmojis = <String>[
  '😀',
  '😁',
  '😂',
  '🤣',
  '😊',
  '😍',
  '🥰',
  '😎',
  '🤔',
  '😭',
  '😡',
  '👍',
  '👏',
  '🙏',
  '🎉',
  '❤️',
  '🔥',
  '✨',
];

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
    // Reply mode
    this.replyTargetName,
    this.onCancelReply,
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

  // Reply mode
  final String? replyTargetName;
  final VoidCallback? onCancelReply;

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
  bool _showEmojiPanel = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostDetailCommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyTargetName != null &&
        oldWidget.replyTargetName != widget.replyTargetName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_focusNode.hasFocus) {
        _showEmojiPanel = false;
      }
    });
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

  void _toggleEmojiPanel() {
    if (_showEmojiPanel) {
      _focusNode.requestFocus();
      return;
    }
    _focusNode.unfocus();
    setState(() => _showEmojiPanel = true);
  }

  void _insertEmoji(String emoji) {
    final value = widget.controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, emoji);
    final nextOffset = start + emoji.length;

    widget.controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
  }

  void _deleteBackward() {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) {
      return;
    }

    if (!selection.isCollapsed) {
      final newText = value.text.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      widget.controller.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
        composing: TextRange.empty,
      );
      return;
    }

    if (selection.start <= 0) {
      return;
    }

    final previousCharacter = value.text.characters.getRange(
      0,
      value.text.characters.length,
    );
    final characters = value.text.characters.toList();
    var utf16Offset = 0;
    for (var index = 0; index < characters.length; index++) {
      final char = characters[index];
      final nextOffset = utf16Offset + char.length;
      if (nextOffset == selection.start) {
        final newText = value.text.replaceRange(utf16Offset, nextOffset, '');
        widget.controller.value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: utf16Offset),
          composing: TextRange.empty,
        );
        return;
      }
      utf16Offset = nextOffset;
    }
    previousCharacter;
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
                  if (widget.replyTargetName != null) ...[
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.reply,
                          size: 14,
                          color: CupertinoDynamicColor.resolve(
                            AppColors.primary,
                            context,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.replyTargetName!.isEmpty
                                ? AppLocalizations.of(
                                    context,
                                  ).replyComment
                                : '@${widget.replyTargetName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoDynamicColor.resolve(
                                AppColors.primary,
                                context,
                              ),
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: widget.isWorking
                              ? null
                              : widget.onCancelReply,
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 18,
                            color: CupertinoDynamicColor.resolve(
                              AppColors.mutedForeground,
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
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
                                  placeholder:
                                      widget.replyTargetName == null
                                      ? AppLocalizations.of(
                                          context,
                                        ).postWriteComment
                                      : AppLocalizations.of(
                                          context,
                                        ).replyHint,
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
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(28, 28),
                                onPressed: _toggleEmojiPanel,
                                child: Icon(
                                  _showEmojiPanel
                                      ? CupertinoIcons.keyboard
                                      : CupertinoIcons.smiley,
                                  size: 20,
                                  color: CupertinoDynamicColor.resolve(
                                    _showEmojiPanel
                                        ? AppColors.primary
                                        : AppColors.mutedForeground,
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showEmojiPanel) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        color: CupertinoDynamicColor.resolve(
                          AppColors.secondary,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _commentComposerEmojis
                                .map(
                                  (emoji) => CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 40),
                                    onPressed: () => _insertEmoji(emoji),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _deleteBackward,
                                child: Icon(
                                  CupertinoIcons.delete_left,
                                  size: 20,
                                  color: CupertinoDynamicColor.resolve(
                                    AppColors.mutedForeground,
                                    context,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                onPressed: widget.isWorking
                                    ? null
                                    : _handleSubmit,
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).postCreatePublish,
                                  style: const TextStyle(
                                    color: AppColors.primaryForeground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

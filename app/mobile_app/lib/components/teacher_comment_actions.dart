import 'package:flutter/cupertino.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../models/teacher_comment.dart';
import '../services/teacher_comment_service.dart';
import '../services/error_messages.dart';
import '../ui/app_feedback.dart';
import '../ui/app_fields.dart';
import '../ui/app_theme.dart';

const int kTeacherCommentMaxLength = 2000;

/// 弹出编辑评价底部弹窗；校验通过后调用 [onSaved] 刷新。
Future<void> showTeacherCommentEditDialog(
  BuildContext context,
  TeacherCommentService service,
  TeacherCommentItem comment, {
  required Future<void> Function() onSaved,
}) async {
  final teacherController = TextEditingController(text: comment.teacherName);
  final courseController = TextEditingController(text: comment.courseName);
  final commentController = TextEditingController(text: comment.comment ?? '');

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (dialogContext) {
      var localStar = comment.star;
      var localSubmitting = false;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return _EditDialogContent(
            teacherController: teacherController,
            courseController: courseController,
            commentController: commentController,
            star: localStar,
            isSubmitting: localSubmitting,
            onStarChanged: (value) => setDialogState(() => localStar = value),
            onSubmit: () async {
              setDialogState(() => localSubmitting = true);
              final success = await _submitEdit(
                dialogContext,
                service,
                comment,
                teacherController,
                courseController,
                commentController,
                localStar,
                onSaved,
              );
              if (!dialogContext.mounted) return;
              if (success) {
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() => localSubmitting = false);
              }
            },
          );
        },
      );
    },
  );
}

Future<void> confirmDeleteTeacherComment(
  BuildContext context,
  TeacherCommentService service,
  TeacherCommentItem comment, {
  required Future<void> Function() onDeleted,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await AppFeedback.confirm(
    context,
    title: l10n.teacherCommentsDeleteTitle,
    message: l10n.teacherCommentsDeleteDescription,
    cancelText: l10n.cancel,
    confirmText: l10n.teacherCommentsDelete,
    destructive: true,
  );
  if (confirmed != true) return;

  try {
    await service.deleteTeacherComment(comment.key);
    if (context.mounted) {
      await AppFeedback.showSuccess(
        context,
        message: l10n.teacherCommentsDeleted,
      );
    }
    await onDeleted();
  } catch (error) {
    if (context.mounted) {
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    }
  }
}

Future<bool> _submitEdit(
  BuildContext context,
  TeacherCommentService service,
  TeacherCommentItem comment,
  TextEditingController teacherController,
  TextEditingController courseController,
  TextEditingController commentController,
  int star,
  Future<void> Function() onSaved,
) async {
  final l10n = AppLocalizations.of(context);
  final teacherName = teacherController.text.trim();
  final courseName = courseController.text.trim();
  final commentText = commentController.text.trim();

  if (teacherName.isEmpty) {
    await AppFeedback.showError(
      context,
      message: l10n.teacherCommentsTeacherRequired,
    );
    return false;
  }
  if (courseName.isEmpty) {
    await AppFeedback.showError(
      context,
      message: l10n.teacherCommentsCourseRequired,
    );
    return false;
  }
  if (commentText.length > kTeacherCommentMaxLength) {
    await AppFeedback.showError(
      context,
      message: l10n.teacherCommentsCommentTooLong(kTeacherCommentMaxLength),
    );
    return false;
  }

  try {
    await service.updateTeacherComment(
      comment.key,
      UpdateTeacherCommentRequest(
        teacherName: teacherName,
        courseName: courseName,
        comment: commentText.isEmpty ? null : commentText,
        star: star,
      ),
    );
    if (!context.mounted) return false;
    await AppFeedback.showSuccess(
      context,
      message: l10n.teacherCommentsUpdated,
    );
    await onSaved();
    return true;
  } catch (error) {
    if (!context.mounted) return false;
    await AppFeedback.showError(
      context,
      message: extractErrorFromException(error),
    );
    return false;
  }
}

class _EditDialogContent extends StatelessWidget {
  const _EditDialogContent({
    required this.teacherController,
    required this.courseController,
    required this.commentController,
    required this.star,
    required this.isSubmitting,
    required this.onStarChanged,
    required this.onSubmit,
  });

  final TextEditingController teacherController;
  final TextEditingController courseController;
  final TextEditingController commentController;
  final int star;
  final bool isSubmitting;
  final ValueChanged<int> onStarChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card(context),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.teacherCommentsEditTitle,
                        style: AppTextStyles.sectionTitle(context),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(CupertinoIcons.xmark_circle_fill),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.teacherCommentsEditSubtitle,
                  style: AppTextStyles.muted(context),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: teacherController,
                  placeholder: l10n.teacherCommentsTeacherPlaceholder,
                  prefix: const Icon(CupertinoIcons.person, size: 18),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: courseController,
                  placeholder: l10n.teacherCommentsCoursePlaceholder,
                  prefix: const Icon(CupertinoIcons.book, size: 18),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      l10n.teacherCommentsStarLabel,
                      style: AppTextStyles.label(context),
                    ),
                    const SizedBox(width: 12),
                    TeacherCommentStarRating(value: star, onChanged: onStarChanged),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: commentController,
                  placeholder: l10n.teacherCommentsCommentPlaceholder,
                  maxLines: 4,
                  maxLength: kTeacherCommentMaxLength,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    onPressed: isSubmitting ? null : onSubmit,
                    child: isSubmitting
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : Text(l10n.teacherCommentsSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherCommentStarRating extends StatelessWidget {
  const TeacherCommentStarRating({super.key, required this.value, this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = CupertinoDynamicColor.resolve(
      AppColors.primary,
      context,
    );
    final inactiveColor = CupertinoDynamicColor.resolve(
      AppColors.mutedForeground,
      context,
    ).withValues(alpha: 0.35);
    final isInteractive = onChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in [1, 2, 3, 4, 5])
          if (isInteractive)
            CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              onPressed: () => onChanged?.call(item),
              child: Icon(
                item <= value ? CupertinoIcons.star_fill : CupertinoIcons.star,
                size: 26,
                color: item <= value ? activeColor : inactiveColor,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                item <= value ? CupertinoIcons.star_fill : CupertinoIcons.star,
                size: 15,
                color: item <= value ? activeColor : inactiveColor,
              ),
            ),
      ],
    );
  }
}

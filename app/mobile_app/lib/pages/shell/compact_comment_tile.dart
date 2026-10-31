import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../../components/app_avatar.dart';
import '../../models/teacher_comment.dart';
import '../../utils/date_formatters.dart';

/// Single-line course-review row used by the desktop list column.
class CompactCommentTile extends StatelessWidget {
  const CompactCommentTile({
    super.key,
    required this.comment,
    required this.onTap,
    this.isSelected = false,
  });

  final TeacherCommentItem comment;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authorName = comment.author?.name?.trim().isNotEmpty == true
        ? comment.author!.name!.trim()
        : comment.userId;
    final courseName = comment.courseName.trim();
    final title = courseName.isEmpty
        ? comment.teacherName.trim()
        : '${comment.teacherName.trim()} · $courseName';
    final body = comment.comment?.trim().isNotEmpty == true
        ? comment.comment!.trim()
        : l10n.teacherCommentsNoComment;
    final time = formatRelativeDateTime(comment.createdOn, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(McRadii.md),
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? context.mc.primary.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(McRadii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(url: comment.author?.avatar, name: authorName, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: context.mc.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: context.mc.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: context.mc.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.star_fill,
                        size: 10,
                        color: context.mc.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${comment.star}',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: context.mc.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

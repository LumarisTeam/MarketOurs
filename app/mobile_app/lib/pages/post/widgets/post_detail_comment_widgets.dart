import 'package:flutter/cupertino.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../models/comment.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/app_widgets.dart';
import '../../../utils/date_formatters.dart';
import '../image_viewer_screen.dart';

const int postDetailMaxCommentImages = 3;

class PostDetailCommentThread extends StatelessWidget {
  const PostDetailCommentThread({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onAuthorTapForUser,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
    required this.onDislike,
    required this.onReplyChild,
    required this.onEditChild,
    required this.onDeleteChild,
    required this.onLikeChild,
    required this.onDislikeChild,
    required this.likedComments,
    required this.dislikedComments,
  });

  final CommentDto comment;
  final String? currentUserId;
  final ValueChanged<String> onAuthorTapForUser;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final ValueChanged<CommentDto> onReplyChild;
  final ValueChanged<CommentDto>? onEditChild;
  final ValueChanged<CommentDto>? onDeleteChild;
  final ValueChanged<CommentDto> onLikeChild;
  final ValueChanged<CommentDto> onDislikeChild;
  final Set<String> likedComments;
  final Set<String> dislikedComments;

  @override
  Widget build(BuildContext context) {
    final flatReplies = _flattenReplies(comment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentCard(
          comment: comment,
          onAuthorTap: comment.userId == null
              ? null
              : () => onAuthorTapForUser(comment.userId!),
          onReply: onReply,
          onEdit: onEdit,
          onDelete: onDelete,
          onLike: onLike,
          onDislike: onDislike,
          isLiked: likedComments.contains(comment.id),
          isDisliked: dislikedComments.contains(comment.id),
        ),
        if (flatReplies.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(left: 44, top: 12),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: CupertinoDynamicColor.resolve(
                    AppColors.border,
                    context,
                  ).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                for (final flat in flatReplies) ...[
                  _CommentCard(
                    comment: flat.comment,
                    isReply: true,
                    replyToName: flat.replyTo?.author?.name,
                    onAuthorTap: flat.comment.userId == null
                        ? null
                        : () => onAuthorTapForUser(flat.comment.userId!),
                    onReply: () => onReplyChild(flat.comment),
                    onEdit: currentUserId == flat.comment.userId
                        ? () => onEditChild?.call(flat.comment)
                        : null,
                    onDelete: currentUserId == flat.comment.userId
                        ? () => onDeleteChild?.call(flat.comment)
                        : null,
                    onLike: () => onLikeChild(flat.comment),
                    onDislike: () => onDislikeChild(flat.comment),
                    isLiked: likedComments.contains(flat.comment.id),
                    isDisliked: dislikedComments.contains(flat.comment.id),
                  ),
                  if (flat != flatReplies.last) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: CupertinoDynamicColor.resolve(
            AppColors.border,
            context,
          ).withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FlatReply {
  const _FlatReply({required this.comment, this.replyTo});

  final CommentDto comment;
  final CommentDto? replyTo;
}

List<_FlatReply> _flattenReplies(CommentDto root) {
  final out = <_FlatReply>[];

  void walk(List<CommentDto>? nodes, CommentDto parent, bool parentIsRoot) {
    if (nodes == null) return;
    for (final child in nodes) {
      out.add(
        _FlatReply(comment: child, replyTo: parentIsRoot ? null : parent),
      );
      walk(child.repliedComments, child, false);
    }
  }

  walk(root.repliedComments, root, true);
  out.sort((a, b) {
    final at = a.comment.createdAt;
    final bt = b.comment.createdAt;
    if (at == null || bt == null) return 0;
    return at.compareTo(bt);
  });
  return out;
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    this.onAuthorTap,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    required this.onLike,
    required this.onDislike,
    this.isLiked = false,
    this.isDisliked = false,
    this.isReply = false,
    this.replyToName,
  });

  final CommentDto comment;
  final VoidCallback? onAuthorTap;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final bool isLiked;
  final bool isDisliked;
  final bool isReply;
  final String? replyToName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppAvatar(
              url: comment.author?.avatar,
              name: comment.author?.name,
              size: isReply ? 28 : 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author?.name ?? '匿名用户',
                    style: TextStyle(
                      fontSize: isReply ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatEditedRelativeDateTime(
                      comment.createdAt,
                      comment.updatedAt,
                      l10n: AppLocalizations.of(context),
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CupertinoDynamicColor.resolve(
                        AppColors.mutedForeground,
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _CommentActionIcon(
              icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              label: '${comment.likes ?? 0}',
              onTap: onLike,
              active: isLiked,
              activeColor: const Color(0xFFFF5A5F),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: isReply ? 38 : 42, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    if (replyToName != null && replyToName!.isNotEmpty)
                      TextSpan(
                        text: '@$replyToName ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    TextSpan(text: comment.content ?? ''),
                  ],
                ),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: CupertinoDynamicColor.resolve(
                    AppColors.foreground,
                    context,
                  ),
                ),
              ),
              CommentImageGrid(images: comment.images ?? const []),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TextAction(label: AppLocalizations.of(context).reply, onTap: onReply),
                  if (onEdit != null) ...[
                    const SizedBox(width: 16),
                    _TextAction(label: AppLocalizations.of(context).editPostAction, onTap: onEdit!),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 16),
                    _TextAction(
                      label: AppLocalizations.of(context).deletePostAction,
                      onTap: onDelete!,
                      activeColor: AppColors.destructive,
                      active: true,
                    ),
                  ],
                  const Spacer(),
                  _CommentActionIcon(
                    icon: isDisliked
                        ? CupertinoIcons.hand_thumbsdown_fill
                        : CupertinoIcons.hand_thumbsdown,
                    onTap: onDislike,
                    active: isDisliked,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentImageGrid extends StatelessWidget {
  const CommentImageGrid({super.key, required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final previewSize = images.length == 1 ? 132.0 : 82.0;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0;
              i < images.length && i < postDetailMaxCommentImages;
              i++)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) =>
                        ImageViewerScreen(images: images, initialIndex: i),
                  ),
                );
              },
              child: Hero(
                tag: 'image_${images[i]}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: ColoredBox(
                    color: CupertinoDynamicColor.resolve(
                      AppColors.secondary,
                      context,
                    ),
                    child: Image.network(
                      images[i],
                      width: previewSize,
                      height: previewSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: previewSize,
                        height: previewSize,
                        color: AppColors.secondary,
                        alignment: Alignment.center,
                        child: const Icon(CupertinoIcons.photo),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentActionIcon extends StatelessWidget {
  const _CommentActionIcon({
    required this.icon,
    this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ??
              CupertinoDynamicColor.resolve(AppColors.primary, context))
        : CupertinoDynamicColor.resolve(AppColors.mutedForeground, context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = AppColors.primary,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final resolvedMuted = CupertinoDynamicColor.resolve(
      AppColors.mutedForeground,
      context,
    );
    final resolvedActive = CupertinoDynamicColor.resolve(activeColor, context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: active ? resolvedActive : resolvedMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

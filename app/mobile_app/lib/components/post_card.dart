import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/models/post.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/post_feed_provider.dart';
import 'package:mobile_app/router/app_router.dart';
import 'package:mobile_app/services/error_messages.dart';
import 'package:mobile_app/services/follow_service.dart';
import 'package:mobile_app/services/share_service.dart';
import 'package:mobile_app/ui/app_feedback.dart';
import 'package:mobile_app/ui/app_theme.dart';
import 'package:mobile_app/ui/app_widgets.dart';
import 'package:mobile_app/components/app_network_image.dart';
import 'package:mobile_app/utils/date_formatters.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final PostDto post;
  static const _shareService = ShareService();

  Future<void> _handleShare(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await _shareService.sharePost(post, sharePositionOrigin: origin);
    } catch (_) {
      if (context.mounted) {
        await AppFeedback.showError(context, message: AppLocalizations.of(context).shareFailed);
      }
    }
  }

  void _showPostActions(BuildContext context, WidgetRef ref, bool isOwner) {
    final l10n = AppLocalizations.of(context);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          if (isOwner) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(buildPostDetailLocation(post.id));
              },
              child: Text(l10n.postEdit),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleDelete(context, ref);
              },
              child: Text(l10n.postDeleteTitle),
            ),
          ] else
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleBlock(context, ref);
              },
              child: Text(l10n.profileBlock),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppFeedback.confirm(
      context,
      message: l10n.postDeleteConfirm,
      title: l10n.postDeleteTitle,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(postServiceProvider).deletePost(post.id);
      if (context.mounted) {
        await AppFeedback.showSuccess(context, message: l10n.postDeleted);
      }
    } catch (error) {
      if (context.mounted) {
        await AppFeedback.showError(
          context,
          message: extractErrorFromException(error),
        );
      }
    }
  }

  Future<void> _handleBlock(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final targetName = post.author?.name ?? l10n.profileBlock;
    final confirmed = await AppFeedback.confirm(
      context,
      message: l10n.blockConfirmMessage(targetName),
      title: l10n.profileBlock,
      confirmText: l10n.profileBlock,
      cancelText: l10n.cancel,
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      final userId = post.userId;
      if (userId == null || userId.isEmpty) return;
      await FollowService().blockUser(userId);
      if (context.mounted) {
        await AppFeedback.showSuccess(context, message: l10n.blockSuccess);
      }
    } catch (error) {
      if (context.mounted) {
        await AppFeedback.showError(
          context,
          message: extractErrorFromException(error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = post.title?.trim().isNotEmpty == true
        ? post.title!.trim()
        : l10n.postUnnamed;
    final content = post.content?.trim().isNotEmpty == true
        ? post.content!.trim()
        : l10n.postNoContent;
    final excerpt = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

    final authState = ref.watch(authControllerProvider).asData?.value;
    final user = authState?.user;
    final isOwner = user != null && post.userId == user.id;

    return AppTappableCard(
      padding: EdgeInsets.zero,
      radius: AppRadii.xl,
      onPressed: () => context.push(buildPostDetailLocation(post.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                AppAvatar(
                  url: post.author?.avatar,
                  name: post.author?.name,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author?.name ?? l10n.anonymousUser,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatEditedRelativeDateTime(
                          post.createdAt,
                          post.updatedAt,
                          l10n: AppLocalizations.of(context),
                        ),
                        style: AppTextStyles.label(context),
                      ),
                    ],
                  ),
                ),
                if (user != null)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => _showPostActions(context, ref, isOwner),
                    child: const Icon(
                      CupertinoIcons.ellipsis,
                      size: 18,
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: AppTextStyles.sectionTitle(
                context,
              ).copyWith(fontSize: 18, height: 1.3),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    excerpt,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 15,
                      color: CupertinoDynamicColor.resolve(
                        AppColors.foreground,
                        context,
                      ).withValues(alpha: 0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.images?.isNotEmpty == true) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: AppNetworkImage(
                        url: post.images!.first,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CupertinoDynamicColor.resolve(
                    AppColors.border,
                    context,
                  ).withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                _StatItem(
                  icon: CupertinoIcons.heart,
                  label: '${post.likes ?? 0}',
                ),
                const SizedBox(width: 24),
                _StatItem(
                  icon: CupertinoIcons.eye,
                  label: '${post.watch ?? 0}',
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _handleShare(context),
                  child: const Icon(
                    CupertinoIcons.share,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = CupertinoDynamicColor.resolve(
      active ? AppColors.destructive : AppColors.mutedForeground,
      context,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: resolvedColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: resolvedColor,
          ),
        ),
      ],
    );
  }
}

class SimplePostCard extends StatelessWidget {
  const SimplePostCard({super.key, required this.post});

  final PostDto post;
  static const _shareService = ShareService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppTappableCard(
      padding: EdgeInsets.zero,
      onPressed: () => context.push(buildPostDetailLocation(post.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title?.trim().isNotEmpty == true
                      ? post.title!.trim()
                      : l10n.postUnnamed,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.content?.trim().isNotEmpty == true
                      ? post.content!.trim()
                      : l10n.postNoContentDesc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    height: 1.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CupertinoDynamicColor.resolve(
                    AppColors.border,
                    context,
                  ).withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                _StatItem(
                  icon: CupertinoIcons.heart,
                  label: '${post.likes ?? 0}',
                  active: false,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  icon: CupertinoIcons.eye,
                  label: '${post.watch ?? 0}',
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _handleShare(context),
                  child: const Icon(
                    CupertinoIcons.share,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await _shareService.sharePost(post, sharePositionOrigin: origin);
    } catch (_) {
      if (context.mounted) {
        await AppFeedback.showError(context, message: AppLocalizations.of(context).shareFailed);
      }
    }
  }
}

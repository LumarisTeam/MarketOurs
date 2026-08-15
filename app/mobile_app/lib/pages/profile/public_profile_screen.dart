import 'package:flutter/cupertino.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/components/post_card.dart';
import 'package:mobile_app/ui/app_theme.dart';

import '../../models/post.dart';
import '../../models/user.dart';
import '../../models/teacher_comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../services/follow_service.dart';
import '../../services/user_service.dart';
import '../../services/teacher_comment_service.dart';
import '../../services/error_messages.dart';
import '../../components/report_sheet.dart';
import '../../components/teacher_comment_actions.dart';
import '../../models/report.dart';
import '../../ui/app_responsive.dart';
import '../../ui/app_widgets.dart';
import '../../utils/date_formatters.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  static const int _pageSize = 10;

  final _userService = UserService();
  final _followService = FollowService();
  final _teacherCommentService = TeacherCommentService();
  late final ScrollController _scrollController;
  int _loadVersion = 0;
  PublicUserProfileDto? _profile;
  List<PostDto> _recentPosts = const [];
  List<TeacherCommentItem> _teacherComments = const [];
  bool _isLoading = true;
  String? _errorMessage;
  int _postsPageIndex = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;

  bool _isFollowing = false;
  bool _isBlocked = false;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasNextPage) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMorePosts();
    }
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId == widget.userId) {
      return;
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _load();
  }

  Future<void> _load() async {
    final requestVersion = ++_loadVersion;
    final requestUserId = widget.userId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _profile = null;
      _recentPosts = const [];
      _teacherComments = const [];
      _postsPageIndex = 1;
      _hasNextPage = false;
      _isLoadingMore = false;
    });

    try {
      final profileFuture = _userService.getPublicProfile(requestUserId);
      final postsFuture = ref
          .read(postServiceProvider)
          .getUserPosts(requestUserId, pageIndex: 1, pageSize: _pageSize);
      final commentsFuture =
          _teacherCommentService.getUserComments(requestUserId);

      final profileResponse = await profileFuture;
      final postsResponse = await postsFuture;
      final commentsResponse = await commentsFuture;
      final profile = profileResponse.data;
      final postsPage = postsResponse.data;

      if (profile == null) {
        throw Exception('User not found');
      }

      if (!mounted ||
          requestVersion != _loadVersion ||
          requestUserId != widget.userId) {
        return;
      }

      setState(() {
        _profile = profile;
        _recentPosts = postsPage?.items ?? const <PostDto>[];
        _teacherComments = commentsResponse.data ?? const <TeacherCommentItem>[];
        _postsPageIndex = postsPage?.pageIndex ?? 1;
        _hasNextPage = postsPage?.hasNextPage ?? false;
        _followerCount = profile.followerCount;
        _followingCount = profile.followingCount;
        _isFollowing = profile.relationshipStatus?.isFollowing ?? false;
        _isBlocked = profile.relationshipStatus?.isBlocked ?? false;
      });
    } catch (error) {
      if (!mounted ||
          requestVersion != _loadVersion ||
          requestUserId != widget.userId) {
        return;
      }
      setState(() {
        _errorMessage = extractErrorFromException(error);
      });
    } finally {
      if (mounted &&
          requestVersion == _loadVersion &&
          requestUserId == widget.userId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasNextPage) return;

    final requestVersion = _loadVersion;
    final requestUserId = widget.userId;

    setState(() => _isLoadingMore = true);
    try {
      final response = await ref
          .read(postServiceProvider)
          .getUserPosts(
            requestUserId,
            pageIndex: _postsPageIndex + 1,
            pageSize: _pageSize,
          );
      final page = response.data;
      if (!mounted ||
          page == null ||
          requestVersion != _loadVersion ||
          requestUserId != widget.userId) {
        return;
      }

      final existingIds = _recentPosts.map((post) => post.id).toSet();
      final nextItems = page.items
          .where((post) => !existingIds.contains(post.id))
          .toList();

      setState(() {
        _recentPosts = [..._recentPosts, ...nextItems];
        _postsPageIndex = page.pageIndex;
        _hasNextPage = page.hasNextPage;
      });
    } catch (_) {
      // Keep current posts and allow retry on next scroll.
    } finally {
      if (mounted &&
          requestVersion == _loadVersion &&
          requestUserId == widget.userId) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _handleToggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    try {
      final result = await _followService.toggleFollow(widget.userId);
      if (mounted && result.data != null) {
        setState(() {
          _isFollowing = result.data!.isFollowing;
          _followerCount = result.data!.followerCount;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _followLoading = false);
  }

  Future<void> _handleToggleBlock() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    try {
      if (_isBlocked) {
        await _followService.unblockUser(widget.userId);
        if (mounted) setState(() => _isBlocked = false);
      } else {
        await _followService.blockUser(widget.userId);
        if (mounted) {
          setState(() {
            _isBlocked = true;
            _isFollowing = false;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _followLoading = false);
  }

  Future<void> _reportUser() => showReportSheet(context, targetType: ReportTargetType.user, targetId: widget.userId);

  Future<void> _reloadComments() async {
    try {
      final response = await _teacherCommentService.getUserComments(widget.userId);
      if (mounted) {
        setState(() => _teacherComments = response.data ?? const []);
      }
    } catch (_) {}
  }

  Future<void> _editComment(TeacherCommentItem comment) =>
      showTeacherCommentEditDialog(
        context,
        _teacherCommentService,
        comment,
        onSaved: _reloadComments,
      );

  Future<void> _deleteComment(TeacherCommentItem comment) =>
      confirmDeleteTeacherComment(
        context,
        _teacherCommentService,
        comment,
        onDeleted: _reloadComments,
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).asData?.value;
    final isMe = authState?.user?.id == widget.userId;

    if (_isLoading) {
      return AppPageScaffold(
        navigationBarStyle: AppNavigationBarStyle.compact,
        title: AppLocalizations.of(context).profilePublicProfile,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return AppPageScaffold(
        navigationBarStyle: AppNavigationBarStyle.compact,
        title: AppLocalizations.of(context).profilePublicProfile,
        child: _ErrorState(message: _errorMessage ?? AppLocalizations.of(context).postUserNotFound, onRetry: _load),
      );
    }

    return AppPageScaffold(
      title: AppLocalizations.of(context).profilePublicProfile,
      navigationBarStyle: AppNavigationBarStyle.compact,
      scrollController: _scrollController,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _load),
        SliverToBoxAdapter(
          child: AppResponsiveCenter(
            padding: AppResponsive.sliverPagePadding(context),
            child: AppTwoPane(
              key: const ValueKey('public-profile-responsive-two-pane'),
              secondaryFirstOnWide: true,
              secondary: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHero(profile: _profile!, isMe: isMe),
                  const SizedBox(height: 12),
                  _FollowStats(
                    followerCount: _followerCount,
                    followingCount: _followingCount,
                  ),
                  if (!isMe &&
                      ref.watch(authControllerProvider).asData?.value.user !=
                          null) ...[
                    const SizedBox(height: 12),
                    _FollowBlockButtons(
                      isFollowing: _isFollowing,
                      isBlocked: _isBlocked,
                      isLoading: _followLoading,
                      onToggleFollow: _handleToggleFollow,
                      onToggleBlock: _handleToggleBlock,
                      onReport: _reportUser,
                    ),
                  ],
                ],
              ),
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RecentPostsSection(
                    posts: _recentPosts,
                    isLoadingMore: _isLoadingMore,
                    hasNextPage: _hasNextPage,
                    isMe: isMe,
                  ),
                  const SizedBox(height: 28),
                  _TeacherCommentsSection(
                    comments: _teacherComments,
                    isMe: isMe,
                    onEdit: _editComment,
                    onDelete: _deleteComment,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentPostsSection extends StatelessWidget {
  const _RecentPostsSection({
    required this.posts,
    required this.isLoadingMore,
    required this.hasNextPage,
    required this.isMe,
  });

  final List<PostDto> posts;
  final bool isLoadingMore;
  final bool hasNextPage;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).profileRecentPosts,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: CupertinoDynamicColor.resolve(AppColors.foreground, context),
          ),
        ),
        if (isMe) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).profileRecentPostsSubtitle,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ],
        const SizedBox(height: 16),
        if (posts.isEmpty)
          AppSectionCard(
            child: Text(AppLocalizations.of(context).profileNoPublicPosts),
          )
        else
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SimplePostCard(post: post),
            ),
          ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (!hasNextPage && posts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Center(
              child: Text(
                AppLocalizations.of(context).profileReachedEnd,
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.isMe});

  final PublicUserProfileDto profile;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(url: profile.avatar, name: profile.name, size: 72),
          const SizedBox(height: 16),
          Text(
            profile.name?.trim().isNotEmpty == true
                ? profile.name!.trim()
                : AppLocalizations.of(context).profileNoNickname,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: CupertinoDynamicColor.resolve(
                AppColors.foreground,
                context,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isMe)
                _MetaChip(label: AppLocalizations.of(context).profileThisIsYou),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.info?.trim().isNotEmpty == true
                ? profile.info!.trim()
                : AppLocalizations.of(context).profileOwnerLowkey,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: CupertinoDynamicColor.resolve(
                AppColors.mutedForeground,
                context,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${AppLocalizations.of(context).profileJoinDate} '
            '${formatYmdDate(profile.createdAt).isEmpty ? AppLocalizations.of(context).profileUnknownDate : formatYmdDate(profile.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoDynamicColor.resolve(
                AppColors.mutedForeground,
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(AppColors.secondary, context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(AppColors.foreground, context),
        ),
      ),
    );
  }
}

class _FollowStats extends StatelessWidget {
  const _FollowStats({
    required this.followerCount,
    required this.followingCount,
  });

  final int followerCount;
  final int followingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSectionCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              children: [
                Text(
                  '$followerCount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CupertinoDynamicColor.resolve(
                      AppColors.foreground,
                      context,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).profileFollowers,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoDynamicColor.resolve(
                      AppColors.mutedForeground,
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppSectionCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              children: [
                Text(
                  '$followingCount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CupertinoDynamicColor.resolve(
                      AppColors.foreground,
                      context,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).profileFollowing,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoDynamicColor.resolve(
                      AppColors.mutedForeground,
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowBlockButtons extends StatelessWidget {
  const _FollowBlockButtons({
    required this.isFollowing,
    required this.isBlocked,
    required this.isLoading,
    required this.onToggleFollow,
    required this.onToggleBlock,
    required this.onReport,
  });

  final bool isFollowing;
  final bool isBlocked;
  final bool isLoading;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: isFollowing
                ? AppColors.secondary
                : CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(12),
            onPressed: isLoading || isBlocked ? null : onToggleFollow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFollowing
                      ? CupertinoIcons.person_badge_minus
                      : CupertinoIcons.person_badge_plus,
                  size: 18,
                  color: isFollowing
                      ? AppColors.foreground
                      : CupertinoColors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  isFollowing
                      ? AppLocalizations.of(context).profileUnfollow
                      : AppLocalizations.of(context).profileFollowing,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isFollowing
                        ? AppColors.foreground
                        : CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: isBlocked
              ? CupertinoColors.systemRed.withValues(alpha: 0.15)
              : AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          onPressed: isLoading ? null : onToggleBlock,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBlocked
                    ? CupertinoIcons.hand_raised_slash
                    : CupertinoIcons.hand_raised,
                size: 18,
                color: isBlocked
                    ? CupertinoColors.systemRed
                    : AppColors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                isBlocked
                    ? AppLocalizations.of(context).profileUnblock
                    : AppLocalizations.of(context).profileBlock,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isBlocked
                      ? CupertinoColors.systemRed
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          onPressed: isLoading ? null : onReport,
          child: const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.person_crop_circle_badge_exclam,
              size: 48,
              color: CupertinoColors.systemGrey2,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppPrimaryButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).reload)),
          ],
        ),
      ),
    );
  }
}

class _TeacherCommentsSection extends StatelessWidget {
  const _TeacherCommentsSection({
    required this.comments,
    required this.isMe,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherCommentItem> comments;
  final bool isMe;
  final ValueChanged<TeacherCommentItem> onEdit;
  final ValueChanged<TeacherCommentItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teacherCommentsTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: CupertinoDynamicColor.resolve(AppColors.foreground, context),
          ),
        ),
        const SizedBox(height: 16),
        if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card(context),
            child: Text(
              isMe
                  ? l10n.teacherCommentsMineEmpty
                  : l10n.teacherCommentsEmptyList,
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(context),
            ),
          )
        else
          for (final comment in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TeacherCommentCard(
                comment: comment,
                isMine: isMe,
                onEdit: () => onEdit(comment),
                onDelete: () => onDelete(comment),
              ),
            ),
      ],
    );
  }
}

class _TeacherCommentCard extends StatelessWidget {
  const _TeacherCommentCard({
    required this.comment,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherCommentItem comment;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  void _openActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              onEdit();
            },
            child: Text(l10n.teacherCommentsEdit),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: Text(l10n.teacherCommentsDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final commentText = comment.comment?.trim().isNotEmpty == true
        ? comment.comment!.trim()
        : l10n.teacherCommentsNoComment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${comment.teacherName} - ${comment.courseName}',
                  style: AppTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 17, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!comment.isReview) ...[
                const SizedBox(width: 8),
                _StatusBadge(label: l10n.teacherCommentsStatusPending),
              ],
              if (isMine) ...[
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _openActions(context),
                  child: const Icon(
                    CupertinoIcons.ellipsis,
                    size: 20,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(commentText, style: AppTextStyles.body(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              TeacherCommentStarRating(value: comment.star),
              const SizedBox(width: 12),
              Text(
                formatRelativeDateTime(comment.createdOn, l10n),
                style: AppTextStyles.label(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoDynamicColor.resolve(
      AppColors.mutedForeground,
      context,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

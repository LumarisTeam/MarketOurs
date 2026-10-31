import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../../components/app_avatar.dart';
import '../../components/teacher_comment_actions.dart';
import '../../models/teacher_comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../router/app_router.dart';
import '../../services/error_messages.dart';
import '../../services/teacher_comment_service.dart';
import '../../ui/app_responsive.dart';
import '../../utils/date_formatters.dart';
import '../shell/compact_comment_tile.dart';

class TeacherCommentsScreen extends ConsumerStatefulWidget {
  const TeacherCommentsScreen({super.key});

  @override
  ConsumerState<TeacherCommentsScreen> createState() =>
      _TeacherCommentsScreenState();
}

class _TeacherCommentsScreenState extends ConsumerState<TeacherCommentsScreen> {
  static const _commentMaxLength = 2000;
  static const _pageSize = 20;

  final _service = TeacherCommentService();
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  final _teacherController = TextEditingController();
  final _courseController = TextEditingController();
  final _commentController = TextEditingController();

  List<TeacherCommentItem> _comments = const [];
  String _activeKeyword = '';
  int _page = 1;
  int _star = 5;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    _teacherController.dispose();
    _courseController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _loadComments('');
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 480) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading || _isLoadingMore) {
      return;
    }
    await _loadComments(_activeKeyword, append: true);
  }

  Future<void> _loadComments(String keyword, {bool append = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    final nextKeyword = keyword.trim();
    final nextPage = append ? _page + 1 : 1;
    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
    });
    try {
      final commentsResponse = await _service.searchApprovedComments(
        keyword: nextKeyword.isEmpty ? null : nextKeyword,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      final pageData = commentsResponse.data;
      final nextItems = pageData?.items ?? const <TeacherCommentItem>[];
      setState(() {
        _activeKeyword = nextKeyword;
        _page = nextPage;
        _hasMore = pageData?.hasNextPage ?? false;
        _comments = append ? [..._comments, ...nextItems] : nextItems;
      });
    } catch (error) {
      if (!mounted) return;
      await McFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<bool> _submit() async {
    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authControllerProvider).asData?.value;
    final user = authState?.user;
    if (user == null) {
      context.go(AppRoutePaths.login);
      return false;
    }

    final teacherName =
        (_teacherController.text.trim().isNotEmpty
                ? _teacherController.text
                : '')
            .trim();
    final courseName = _courseController.text.trim();
    final comment = _commentController.text.trim();

    if (teacherName.isEmpty) {
      await McFeedback.showError(
        context,
        message: l10n.teacherCommentsTeacherRequired,
      );
      return false;
    }
    if (courseName.isEmpty) {
      await McFeedback.showError(
        context,
        message: l10n.teacherCommentsCourseRequired,
      );
      return false;
    }
    if (comment.length > _commentMaxLength) {
      await McFeedback.showError(
        context,
        message: l10n.teacherCommentsCommentTooLong(_commentMaxLength),
      );
      return false;
    }

    try {
      await _service.createTeacherComment(
        CreateTeacherCommentRequest(
          teacherName: teacherName,
          courseName: courseName,
          comment: comment.isEmpty ? null : comment,
          star: _star,
        ),
      );
      if (!mounted) return false;
      _searchController.text = teacherName;
      _teacherController.text = teacherName;
      _courseController.clear();
      _commentController.clear();
      setState(() => _star = 5);
      await McFeedback.showSuccess(
        context,
        message: l10n.teacherCommentsSubmitted,
      );
      await _loadComments(_activeKeyword);
      return true;
    } catch (error) {
      if (!mounted) return false;
      await McFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    }
    return false;
  }

  Future<void> _editComment(TeacherCommentItem comment) =>
      showTeacherCommentEditDialog(
        context,
        _service,
        comment,
        onSaved: () => _loadComments(_activeKeyword),
      );

  Future<void> _deleteComment(TeacherCommentItem comment) =>
      confirmDeleteTeacherComment(
        context,
        _service,
        comment,
        onDeleted: () => _loadComments(_activeKeyword),
      );

  Future<void> _openSubmitDialog() async {
    await showMcBottomSheet<void>(
      context: context,
      builder: (dialogContext) {
        var localStar = _star;
        var localSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return _SubmitDialogContent(
              teacherController: _teacherController,
              courseController: _courseController,
              commentController: _commentController,
              star: localStar,
              isAuthenticated:
                  ref.read(authControllerProvider).asData?.value.user != null,
              isSubmitting: localSubmitting,
              onStarChanged: (value) {
                setDialogState(() => localStar = value);
                setState(() => _star = value);
              },
              onSubmit: () async {
                setDialogState(() => localSubmitting = true);
                final success = await _submit();
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

  @override
  Widget build(BuildContext context) {
    ref.listen<NavigationRefreshEvent?>(navigationRefreshTargetProvider, (
      _,
      event,
    ) {
      if (event?.index == 1 && mounted) {
        unawaited(_loadComments(_activeKeyword));
      }
    });
    final l10n = AppLocalizations.of(context);
    final isDesktop = AppResponsive.isDesktop(context);
    final currentUserId = ref
        .watch(authControllerProvider)
        .asData
        ?.value
        .user
        ?.id;

    final searchField = CupertinoSearchTextField(
      key: const ValueKey('teacher-comments-search-field'),
      controller: _searchController,
      placeholder: l10n.teacherCommentsSearchPlaceholder,
      borderRadius: BorderRadius.circular(McRadii.md),
      backgroundColor: context.mc.secondary,
      onSubmitted: (value) => _loadComments(value),
      onChanged: (value) {
        if (value.trim().isEmpty && _activeKeyword.isNotEmpty) {
          _loadComments('');
        }
      },
    );

    final Widget listSliver;
    if (_isLoading) {
      listSliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    } else if (_comments.isEmpty) {
      final emptyState = McEmpty.placeholder(
        icon: _activeKeyword.isEmpty
            ? CupertinoIcons.book
            : CupertinoIcons.search,
        title: _activeKeyword.isEmpty
            ? l10n.teacherCommentsEmptyList
            : l10n.teacherCommentsNoApprovedComments,
        description: l10n.teacherCommentsSearchFirst,
      );
      listSliver = isDesktop
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: emptyState),
              ),
            )
          : AppResponsiveSliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: emptyState,
            );
    } else if (isDesktop) {
      // Desktop: compact single-line rows inside the 340px list column.
      listSliver = SliverPadding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        sliver: SliverList.builder(
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            return CompactCommentTile(
              comment: comment,
              onTap: () =>
                  unawaited(_showCommentDetail(comment, currentUserId)),
            );
          },
        ),
      );
    } else {
      listSliver = AppResponsiveSliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _CommentListSection(
          comments: _comments,
          isLoadingMore: _isLoadingMore,
          currentUserId: currentUserId,
          onEdit: _editComment,
          onDelete: _deleteComment,
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (isDesktop)
            SliverToBoxAdapter(
              child: _ShellPaneHeader(
                title: l10n.teacherCommentsTitle,
                onAdd: _openSubmitDialog,
              ),
            )
          else
            CupertinoSliverNavigationBar(
              largeTitle: Text(l10n.teacherCommentsTitle),
              backgroundColor: context.mc.background.withValues(alpha: 0.94),
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openSubmitDialog,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 28,
                  color: context.mc.primary,
                ),
              ),
            ),
          CupertinoSliverRefreshControl(
            onRefresh: () => _loadComments(_activeKeyword),
          ),
          SliverToBoxAdapter(
            child: isDesktop
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: searchField,
                  )
                : AppResponsiveCenter(
                    padding: AppResponsive.sliverPagePadding(
                      context,
                      top: 12,
                      bottom: 8,
                    ),
                    child: searchField,
                  ),
          ),
          listSliver,
          if (isDesktop && _isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCommentDetail(
    TeacherCommentItem comment,
    String? currentUserId,
  ) async {
    final isMine = currentUserId != null && comment.userId == currentUserId;
    await showMcBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: _CommentCard(
            comment: comment,
            isMine: isMine,
            onEdit: isMine
                ? () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_editComment(comment));
                  }
                : null,
            onDelete: isMine
                ? () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_deleteComment(comment));
                  }
                : null,
          ),
        ),
      ),
    );
  }

}

class _ShellPaneHeader extends StatelessWidget {
  const _ShellPaneHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.mc.foreground,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onAdd,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 22,
                  color: context.mc.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentListSection extends StatelessWidget {
  const _CommentListSection({
    required this.comments,
    required this.isLoadingMore,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherCommentItem> comments;
  final bool isLoadingMore;
  final String? currentUserId;
  final ValueChanged<TeacherCommentItem> onEdit;
  final ValueChanged<TeacherCommentItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final columnCount = AppResponsive.listColumnCount(context);

    if (columnCount == 1) {
      return Column(
        key: const ValueKey('teacher-comment-feed-columns-1'),
        children: [
          for (final comment in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CommentCard(
                comment: comment,
                isMine:
                    currentUserId != null && comment.userId == currentUserId,
                onEdit: () => onEdit(comment),
                onDelete: () => onDelete(comment),
              ),
            ),
          if (isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CupertinoActivityIndicator()),
            ),
        ],
      );
    }

    return Column(
      key: const ValueKey('teacher-comment-feed-columns-2'),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            final itemWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final comment in comments)
                  SizedBox(
                    width: itemWidth,
                    child: _CommentCard(
                      comment: comment,
                      isMine:
                          currentUserId != null &&
                          comment.userId == currentUserId,
                      onEdit: () => onEdit(comment),
                      onDelete: () => onDelete(comment),
                    ),
                  ),
              ],
            );
          },
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CupertinoActivityIndicator()),
          ),
      ],
    );
  }
}

class _SubmitDialogContent extends StatelessWidget {
  const _SubmitDialogContent({
    required this.teacherController,
    required this.courseController,
    required this.commentController,
    required this.star,
    required this.isAuthenticated,
    required this.isSubmitting,
    required this.onStarChanged,
    required this.onSubmit,
  });

  final TextEditingController teacherController;
  final TextEditingController courseController;
  final TextEditingController commentController;
  final int star;
  final bool isAuthenticated;
  final bool isSubmitting;
  final ValueChanged<int> onStarChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.teacherCommentsCreateTitle, style: context.mc.textSection),
          const SizedBox(height: 4),
          Text(
            l10n.teacherCommentsCreateSubtitle,
            style: context.mc.textMuted,
          ),
          const SizedBox(height: 14),
          if (!isAuthenticated)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(AppRoutePaths.login),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.teacherCommentsLoginRequired),
              ),
            )
          else ...[
            McField.text(
              controller: teacherController,
              placeholder: l10n.teacherCommentsTeacherPlaceholder,
              prefix: const Icon(CupertinoIcons.person, size: 18),
            ),
            const SizedBox(height: 10),
            McField.text(
              controller: courseController,
              placeholder: l10n.teacherCommentsCoursePlaceholder,
              prefix: const Icon(CupertinoIcons.book, size: 18),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  l10n.teacherCommentsStarLabel,
                  style: context.mc.textLabel,
                ),
                const SizedBox(width: 12),
                _StarRating(value: star, onChanged: onStarChanged),
              ],
            ),
            const SizedBox(height: 10),
            McField.text(
              controller: commentController,
              placeholder: l10n.teacherCommentsCommentPlaceholder,
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(McRadii.lg),
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Text(l10n.teacherCommentsSubmit),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    this.isMine = false,
    this.onEdit,
    this.onDelete,
  });

  final TeacherCommentItem comment;
  final bool isMine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  void _openActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              onEdit?.call();
            },
            child: Text(l10n.teacherCommentsEdit),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
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
    final authorName = comment.author?.name?.trim().isNotEmpty == true
        ? comment.author!.name!.trim()
        : comment.userId;

    return McCard.elevated(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                AppAvatar(
                  url: comment.author?.avatar,
                  name: authorName,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatRelativeDateTime(comment.createdOn, l10n),
                        style: context.mc.textLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isMine)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => _openActions(context),
                    child: Icon(
                      CupertinoIcons.ellipsis,
                      size: 20,
                      color: context.mc.secondaryLabel,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.teacherName} - ${comment.courseName}',
                  style: context.mc.textSection.copyWith(
                    fontSize: 18,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(commentText, style: context.mc.textBody),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.mc.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(children: [_StarRating(value: comment.star)]),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.mc.primary;
    final inactiveColor = context.mc.secondaryLabel.withValues(alpha: 0.35);
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

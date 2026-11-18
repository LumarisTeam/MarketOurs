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

class TeacherCommentsScreen extends ConsumerStatefulWidget {
  const TeacherCommentsScreen({super.key, this.courseName});

  final String? courseName;

  @override
  ConsumerState<TeacherCommentsScreen> createState() =>
      _TeacherCommentsScreenState();
}

class _TeacherCommentsScreenState extends ConsumerState<TeacherCommentsScreen> {
  static const _commentMaxLength = 2000;
  static const _pageSize = 20;

  late final TeacherCommentService _service;
  String? get _courseName => widget.courseName?.trim();
  bool get _isDetail => widget.courseName != null;
  List<CourseCommentSummary> _courses = const [];
  CourseCommentSummary? _summary;
  String? _loadError;
  int _requestId = 0;
  bool _failedAppend = false;
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
    _requestId++;
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
    _service = ref.read(teacherCommentServiceProvider);
    _courseController.text = _courseName ?? '';
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
    if (!_hasMore || _isLoading || _isLoadingMore || _loadError != null) {
      return;
    }
    await _loadComments(_activeKeyword, append: true);
  }

  Future<void> _loadComments(String keyword, {bool append = false}) async {
    if (append && (_isLoading || _isLoadingMore)) return;
    final requestId = ++_requestId;
    final nextKeyword = keyword.trim();
    final nextPage = append ? _page + 1 : 1;
    setState(() {
      if (!append && _activeKeyword != nextKeyword) {
        _courses = const [];
        _page = 1;
        _hasMore = false;
      }
      _activeKeyword = nextKeyword;
      _loadError = null;
      _isLoading = !append;
      _isLoadingMore = append;
    });
    try {
      if (_isDetail) {
        if (_courseName == null || _courseName!.isEmpty) {
          throw StateError(
            AppLocalizations.of(context).teacherCommentsCourseRequired,
          );
        }
        final reviewsFuture = _service.getCourseComments(
          _courseName!,
          page: nextPage,
          pageSize: _pageSize,
        );
        final summaryFuture = append
            ? Future<CourseCommentSummary?>.value(null)
            : _service
                  .getCourseSummary(_courseName!)
                  .then((response) => response.data);
        final (reviewsResponse, summary) = await (
          reviewsFuture,
          summaryFuture,
        ).wait;
        if (!mounted || requestId != _requestId) return;
        final data = reviewsResponse.data;
        setState(() {
          _comments = append
              ? [..._comments, ...?data?.items]
              : data?.items ?? [];
          if (!append) _summary = summary;
          _hasMore = data?.hasNextPage ?? false;
          _page = nextPage;
        });
      } else {
        final response = await _service.getCourses(
          keyword: nextKeyword,
          page: nextPage,
          pageSize: _pageSize,
        );
        if (!mounted || requestId != _requestId) return;
        final data = response.data;
        setState(() {
          _courses = append
              ? [..._courses, ...?data?.items]
              : data?.items ?? [];
          _hasMore = data?.hasNextPage ?? false;
          _page = nextPage;
        });
      }
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadError = extractErrorFromException(error);
        _failedAppend = append;
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openCourse(CourseCommentSummary course) async {
    await context.push(
      Uri(
        path: AppRoutePaths.courseComments,
        queryParameters: {'courseName': course.courseName},
      ).toString(),
    );
    if (mounted) await _loadComments(_activeKeyword);
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
      _teacherController.clear();
      _courseController.text = _courseName ?? '';
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
    final currentUserId = ref
        .watch(authControllerProvider)
        .asData
        ?.value
        .user
        ?.id;
    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              _isDetail ? _courseName ?? '' : l10n.teacherCommentsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: _isDetail
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutePaths.teacherComments),
                    child: const Icon(CupertinoIcons.back),
                  )
                : null,
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
          if (!_isDetail)
            SliverToBoxAdapter(
              child: AppResponsiveCenter(
                padding: AppResponsive.sliverPagePadding(
                  context,
                  top: 12,
                  bottom: 8,
                ),
                child: CupertinoSearchTextField(
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
                ),
              ),
            ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            )
          else ...[
            if (_isDetail && _summary != null && _summary!.totalCount > 0)
              SliverToBoxAdapter(
                child: AppResponsiveCenter(
                  padding: const EdgeInsets.all(16),
                  child: CourseRatingSummary(summary: _summary!),
                ),
              ),
            if ((_isDetail ? _comments.isEmpty : _courses.isEmpty) &&
                _loadError == null)
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: McEmpty.placeholder(
                  icon: CupertinoIcons.book,
                  title: _isDetail
                      ? l10n.teacherCommentsNoApprovedComments
                      : l10n.courseCommentsEmpty,
                  description: _isDetail
                      ? l10n.courseCommentsAllTeachers
                      : l10n.teacherCommentsSearchFirst,
                ),
              ),
            if (_isDetail)
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _CommentListSection(
                  comments: _comments,
                  isLoadingMore: _isLoadingMore,
                  currentUserId: currentUserId,
                  onEdit: _editComment,
                  onDelete: _deleteComment,
                ),
              )
            else
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    for (final course in _courses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CourseSummaryCard(
                          course: course,
                          onTap: () => _openCourse(course),
                        ),
                      ),
                    if (_isLoadingMore) const CupertinoActivityIndicator(),
                  ],
                ),
              ),
            if (_loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      CupertinoButton(
                        onPressed: () => _loadComments(
                          _activeKeyword,
                          append: _failedAppend,
                        ),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasMore && !_isLoadingMore && _loadError == null)
              SliverToBoxAdapter(
                child: CupertinoButton(
                  onPressed: _loadMore,
                  child: Text(l10n.postLoadMore),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class CourseSummaryCard extends StatelessWidget {
  const CourseSummaryCard({
    super.key,
    required this.course,
    required this.onTap,
  });
  final CourseCommentSummary course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return McCard.elevated(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.courseName, style: context.mc.textSection),
                  const SizedBox(height: 8),
                  Text(
                    '${course.averageStar.toStringAsFixed(1)} / 5 · ${l10n.courseCommentsCount(course.totalCount)}',
                    style: context.mc.textBody,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class CourseRatingSummary extends StatelessWidget {
  const CourseRatingSummary({super.key, required this.summary});
  final CourseCommentSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return McCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.teacherCommentsAverageStar}: ${summary.averageStar.toStringAsFixed(1)} / 5',
            style: context.mc.textSection,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.courseCommentsCount(summary.totalCount),
            style: context.mc.textBody,
          ),
          const SizedBox(height: 6),
          Text(l10n.courseCommentsAllTeachers, style: context.mc.textMuted),
          const SizedBox(height: 16),
          Text(l10n.courseCommentsDistribution, style: context.mc.textLabel),
          for (final item in summary.starDistribution.reversed)
            Semantics(
              label:
                  '${item.star} / 5: ${l10n.courseCommentsCount(item.count)}',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${item.star} ★',
                        style: context.mc.textLabel,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.mc.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: summary.totalCount == 0
                              ? 0
                              : (item.count / summary.totalCount).clamp(0, 1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.mc.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${item.count}',
                        textAlign: TextAlign.right,
                        style: context.mc.textLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          Text(l10n.teacherCommentsCreateSubtitle, style: context.mc.textMuted),
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

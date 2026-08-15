import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../../models/teacher_comment.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../services/error_messages.dart';
import '../../services/teacher_comment_service.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_fields.dart';
import '../../ui/app_responsive.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';
import '../../utils/date_formatters.dart';

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

  int _mode = 0; // 0 = 浏览评价, 1 = 我的评价
  List<TeacherCommentItem> _myComments = const [];
  bool _isLoadingMine = false;

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
      await AppFeedback.showError(
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
    if (comment.length > _commentMaxLength) {
      await AppFeedback.showError(
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
      await AppFeedback.showSuccess(
        context,
        message: l10n.teacherCommentsSubmitted,
      );
      await _loadComments(_activeKeyword);
      return true;
    } catch (error) {
      if (!mounted) return false;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    }
    return false;
  }

  Future<void> _openSubmitDialog() async {
    await showCupertinoModalPopup<void>(
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

  Future<void> _loadMine() async {
    final authState = ref.read(authControllerProvider).asData?.value;
    final user = authState?.user;
    if (user == null) {
      setState(() => _myComments = const []);
      return;
    }

    setState(() => _isLoadingMine = true);
    try {
      final response = await _service.getMyComments();
      if (!mounted) return;
      setState(() => _myComments = response.data ?? const []);
    } catch (error) {
      if (!mounted) return;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMine = false);
      }
    }
  }

  Future<bool> _edit(
    TeacherCommentItem comment,
    TextEditingController teacherController,
    TextEditingController courseController,
    TextEditingController commentController,
    int star,
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
    if (commentText.length > _commentMaxLength) {
      await AppFeedback.showError(
        context,
        message: l10n.teacherCommentsCommentTooLong(_commentMaxLength),
      );
      return false;
    }

    try {
      await _service.updateTeacherComment(
        comment.key,
        UpdateTeacherCommentRequest(
          teacherName: teacherName,
          courseName: courseName,
          comment: commentText.isEmpty ? null : commentText,
          star: star,
        ),
      );
      if (!mounted) return false;
      await AppFeedback.showSuccess(
        context,
        message: l10n.teacherCommentsUpdated,
      );
      await _loadMine();
      return true;
    } catch (error) {
      if (!mounted) return false;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    }
    return false;
  }

  Future<void> _openEditDialog(TeacherCommentItem comment) async {
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
                final success = await _edit(
                  comment,
                  teacherController,
                  courseController,
                  commentController,
                  localStar,
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

  Future<void> _confirmDelete(TeacherCommentItem comment) async {
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
      await _service.deleteTeacherComment(comment.key);
      if (!mounted) return;
      await AppFeedback.showSuccess(
        context,
        message: l10n.teacherCommentsDeleted,
      );
      await _loadMine();
    } catch (error) {
      if (!mounted) return;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.teacherCommentsTitle),
            backgroundColor: CupertinoDynamicColor.resolve(
              AppColors.background,
              context,
            ).withValues(alpha: 0.94),
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openSubmitDialog,
              child: const Icon(
                CupertinoIcons.plus_circle_fill,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                _mode == 0 ? _loadComments(_activeKeyword) : _loadMine(),
          ),
          SliverToBoxAdapter(
            child: AppResponsiveCenter(
              padding: AppResponsive.sliverPagePadding(
                context,
                top: 12,
                bottom: 8,
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _mode,
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => _mode = value);
                  if (value == 1) {
                    _loadMine();
                  }
                },
                children: {
                  0: Text(l10n.teacherCommentsBrowse),
                  1: Text(l10n.teacherCommentsMyComments),
                },
              ),
            ),
          ),
          if (_mode == 0) ...[
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
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  backgroundColor: AppColors.secondary,
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
            else if (_comments.isEmpty)
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: AppEmptyState(
                  icon: _activeKeyword.isEmpty
                      ? CupertinoIcons.book
                      : CupertinoIcons.search,
                  title: _activeKeyword.isEmpty
                      ? l10n.teacherCommentsEmptyList
                      : l10n.teacherCommentsNoApprovedComments,
                  description: l10n.teacherCommentsSearchFirst,
                ),
              )
            else
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _CommentListSection(
                  comments: _comments,
                  isLoadingMore: _isLoadingMore,
                ),
              ),
          ] else ...[
            if (_isLoadingMine)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              )
            else if (_myComments.isEmpty)
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: AppEmptyState(
                  icon: CupertinoIcons.star,
                  title: l10n.teacherCommentsMineEmpty,
                  description: '',
                ),
              )
            else
              AppResponsiveSliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _MyCommentListSection(
                  comments: _myComments,
                  onEdit: _openEditDialog,
                  onDelete: _confirmDelete,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CommentListSection extends StatelessWidget {
  const _CommentListSection({
    required this.comments,
    required this.isLoadingMore,
  });

  final List<TeacherCommentItem> comments;
  final bool isLoadingMore;

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
              child: _CommentCard(comment: comment),
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
                    child: _CommentCard(comment: comment),
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
                        l10n.teacherCommentsCreateTitle,
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
                  l10n.teacherCommentsCreateSubtitle,
                  style: AppTextStyles.muted(context),
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
                      _StarRating(value: star, onChanged: onStarChanged),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: commentController,
                    placeholder: l10n.teacherCommentsCommentPlaceholder,
                    maxLines: 4,
                    maxLength: 2000,
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
                          : Text(l10n.teacherCommentsSubmit),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final TeacherCommentItem comment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final commentText = comment.comment?.trim().isNotEmpty == true
        ? comment.comment!.trim()
        : l10n.teacherCommentsNoComment;
    final authorName = comment.author?.name?.trim().isNotEmpty == true
        ? comment.author!.name!.trim()
        : comment.userId;

    return AppTappableCard(
      padding: EdgeInsets.zero,
      radius: AppRadii.xl,
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
                        style: AppTextStyles.label(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  style: AppTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 18, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(commentText, style: AppTextStyles.body(context)),
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

class _MyCommentListSection extends StatelessWidget {
  const _MyCommentListSection({
    required this.comments,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherCommentItem> comments;
  final ValueChanged<TeacherCommentItem> onEdit;
  final ValueChanged<TeacherCommentItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final comment in comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _MyCommentCard(
              comment: comment,
              onEdit: () => onEdit(comment),
              onDelete: () => onDelete(comment),
            ),
          ),
      ],
    );
  }
}

class _MyCommentCard extends StatelessWidget {
  const _MyCommentCard({
    required this.comment,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherCommentItem comment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                  style: AppTextStyles.sectionTitle(context).copyWith(
                    fontSize: 18,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(isApproved: comment.isReview),
            ],
          ),
          const SizedBox(height: 10),
          Text(commentText, style: AppTextStyles.body(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StarRating(value: comment.star),
              const SizedBox(width: 12),
              Text(
                formatRelativeDateTime(comment.createdOn, l10n),
                style: AppTextStyles.label(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onPressed: onEdit,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.pencil,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.teacherCommentsEdit,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onPressed: onDelete,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.trash,
                      size: 16,
                      color: AppColors.destructive,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.teacherCommentsDelete,
                      style: const TextStyle(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isApproved});

  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isApproved ? AppColors.primary : AppColors.mutedForeground;
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        isApproved
            ? l10n.teacherCommentsStatusApproved
            : l10n.teacherCommentsStatusPending,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: resolvedColor,
        ),
      ),
    );
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
                    _StarRating(value: star, onChanged: onStarChanged),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: commentController,
                  placeholder: l10n.teacherCommentsCommentPlaceholder,
                  maxLines: 4,
                  maxLength: 2000,
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

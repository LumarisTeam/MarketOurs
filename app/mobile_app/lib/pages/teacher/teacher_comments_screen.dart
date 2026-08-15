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
import '../../ui/app_theme.dart';
import '../../utils/date_formatters.dart';

class TeacherCommentsScreen extends ConsumerStatefulWidget {
  const TeacherCommentsScreen({super.key});

  @override
  ConsumerState<TeacherCommentsScreen> createState() =>
      _TeacherCommentsScreenState();
}

class _TeacherCommentsScreenState extends ConsumerState<TeacherCommentsScreen> {
  static const _commentMaxLength = 2000;

  final _service = TeacherCommentService();
  final _searchController = TextEditingController();
  final _teacherController = TextEditingController();
  final _courseController = TextEditingController();
  final _commentController = TextEditingController();

  TeacherCommentSummary? _summary;
  List<TeacherCommentItem> _comments = const [];
  String _activeTeacherName = '';
  int _star = 5;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _teacherController.dispose();
    _courseController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacher(String teacherName) async {
    final name = teacherName.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final summaryFuture = _service.getSummary(name);
      final commentsFuture = _service.getTeacherComments(name);
      final summaryResponse = await summaryFuture;
      final commentsResponse = await commentsFuture;
      if (!mounted) return;
      setState(() {
        _activeTeacherName = name;
        _teacherController.text = name;
        _summary = summaryResponse.data;
        _comments = commentsResponse.data ?? const <TeacherCommentItem>[];
      });
    } catch (error) {
      if (!mounted) return;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authControllerProvider).asData?.value;
    final user = authState?.user;
    if (user == null) {
      context.go(AppRoutePaths.login);
      return;
    }

    final teacherName =
        (_teacherController.text.trim().isNotEmpty
                ? _teacherController.text
                : _activeTeacherName)
            .trim();
    final courseName = _courseController.text.trim();
    final comment = _commentController.text.trim();

    if (teacherName.isEmpty) {
      await AppFeedback.showError(
        context,
        message: l10n.teacherCommentsTeacherRequired,
      );
      return;
    }
    if (courseName.isEmpty) {
      await AppFeedback.showError(
        context,
        message: l10n.teacherCommentsCourseRequired,
      );
      return;
    }
    if (comment.length > _commentMaxLength) {
      await AppFeedback.showError(
        context,
        message: l10n.teacherCommentsCommentTooLong(_commentMaxLength),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.createTeacherComment(
        CreateTeacherCommentRequest(
          teacherName: teacherName,
          courseName: courseName,
          comment: comment.isEmpty ? null : comment,
          star: _star,
        ),
      );
      if (!mounted) return;
      _searchController.text = teacherName;
      _teacherController.text = teacherName;
      _courseController.clear();
      _commentController.clear();
      setState(() => _star = 5);
      await AppFeedback.showSuccess(
        context,
        message: l10n.teacherCommentsSubmitted,
      );
      await _loadTeacher(teacherName);
    } catch (error) {
      if (!mounted) return;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAuthenticated =
        ref.watch(authControllerProvider).asData?.value.user != null;
    final summary = _summary;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.teacherCommentsTitle),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverList.list(
                children: [
                  Text(
                    l10n.teacherCommentsSubtitle,
                    style: AppTextStyles.muted(context),
                  ),
                  const SizedBox(height: 16),
                  _SearchPanel(
                    controller: _searchController,
                    isLoading: _isLoading,
                    onSearch: () => _loadTeacher(_searchController.text),
                  ),
                  const SizedBox(height: 16),
                  _SummaryPanel(
                    teacherName: _activeTeacherName.isEmpty
                        ? l10n.teacherCommentsEmptyTeacher
                        : _activeTeacherName,
                    averageStar: summary != null && summary.totalCount > 0
                        ? summary.averageStar.toStringAsFixed(1)
                        : '-',
                    totalCount: summary?.totalCount ?? 0,
                    courses: summary?.courses ?? const <String>[],
                  ),
                  const SizedBox(height: 16),
                  _SubmitPanel(
                    teacherController: _teacherController,
                    courseController: _courseController,
                    commentController: _commentController,
                    star: _star,
                    isAuthenticated: isAuthenticated,
                    isSubmitting: _isSubmitting,
                    onStarChanged: (value) => setState(() => _star = value),
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.teacherCommentsApprovedComments,
                    style: AppTextStyles.sectionTitle(context),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _SkeletonCard(),
                  ),
                ),
              )
            else if (_comments.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: _EmptyState(
                    message: _activeTeacherName.isEmpty
                        ? l10n.teacherCommentsSearchFirst
                        : l10n.teacherCommentsNoApprovedComments,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CommentCard(comment: _comments[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: AppDecorations.card(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                placeholder: l10n.teacherCommentsSearchPlaceholder,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => onSearch(),
                prefix: const Icon(CupertinoIcons.search, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onPressed: isLoading ? null : onSearch,
              child: isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : Text(l10n.teacherCommentsSearch),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.teacherName,
    required this.averageStar,
    required this.totalCount,
    required this.courses,
  });

  final String teacherName;
  final String averageStar;
  final int totalCount;
  final List<String> courses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: AppDecorations.card(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: l10n.teacherCommentsCurrentTeacher,
                    value: teacherName,
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: l10n.teacherCommentsAverageStar,
                    value: averageStar,
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: l10n.teacherCommentsTotalCount,
                    value: '$totalCount',
                  ),
                ),
              ],
            ),
            if (courses.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final course in courses) _CoursePill(label: course),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context)),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sectionTitle(context),
        ),
      ],
    );
  }
}

class _SubmitPanel extends StatelessWidget {
  const _SubmitPanel({
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
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: AppDecorations.card(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teacherCommentsCreateTitle,
              style: AppTextStyles.sectionTitle(context),
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
                  CupertinoSlidingSegmentedControl<int>(
                    groupValue: star,
                    children: {
                      for (final value in [1, 2, 3, 4, 5])
                        value: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('$value'),
                        ),
                    },
                    onValueChanged: (value) {
                      if (value != null) onStarChanged(value);
                    },
                  ),
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
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final TeacherCommentItem comment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: AppDecorations.card(context, radius: AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CoursePill(label: comment.courseName),
                const Spacer(),
                Text('${comment.star}/5', style: AppTextStyles.label(context)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              comment.comment?.isNotEmpty == true
                  ? comment.comment!
                  : l10n.teacherCommentsNoComment,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 10),
            Text(
              formatYmdDate(comment.createdOn, separator: '/'),
              style: AppTextStyles.label(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursePill extends StatelessWidget {
  const _CoursePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.pill(context, showBorder: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(label, style: AppTextStyles.label(context)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.mutedCard(context, radius: AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.muted(context),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.mutedCard(context, radius: AppRadii.lg),
      child: const SizedBox(height: 96),
    );
  }
}

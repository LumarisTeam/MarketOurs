import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/models/api_response.dart';
import 'package:mobile_app/models/auth_session.dart';
import 'package:mobile_app/models/paged_result.dart';
import 'package:mobile_app/models/teacher_comment.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/pages/teacher/teacher_comments_screen.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/teacher_comment_service.dart';

const _course = '高等数学 / A&B';
const _summary = CourseCommentSummary(
  courseName: _course,
  totalCount: 26,
  averageStar: 4.4,
  starDistribution: [
    CourseStarCount(star: 1, count: 1),
    CourseStarCount(star: 2, count: 0),
    CourseStarCount(star: 3, count: 2),
    CourseStarCount(star: 4, count: 8),
    CourseStarCount(star: 5, count: 15),
  ],
);

void main() {
  test('course statistics parse integer averages and empty summaries', () {
    final summary = CourseCommentSummary.fromJson({
      'courseName': _course,
      'totalCount': 1,
      'averageStar': 5,
      'latestCommentOn': '2026-11-18T01:00:00Z',
      'starDistribution': [
        for (var star = 1; star <= 5; star++)
          {'star': star, 'count': star == 5 ? 1 : 0},
      ],
    });
    expect(summary.averageStar, 5.0);
    expect(summary.starDistribution.last.count, 1);
    expect(summary.latestCommentOn!.isUtc, isTrue);
    final empty = CourseCommentSummary.fromJson({
      'courseName': _course,
      'totalCount': 0,
      'averageStar': 0,
      'latestCommentOn': null,
      'starDistribution': [
        for (var star = 1; star <= 5; star++) {'star': star, 'count': 0},
      ],
    });
    expect(empty.totalCount, 0);
    expect(empty.latestCommentOn, isNull);
  });

  testWidgets('guest opens course details and returns to refreshed search', (
    tester,
  ) async {
    final service = _FakeService();
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await tester.pumpAndSettle();
    expect(find.byType(CourseSummaryCard), findsOneWidget);
    await tester.enterText(find.byType(CupertinoSearchTextField), '张老师');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(service.keywords.last, '张老师');
    await tester.tap(find.byType(CourseSummaryCard));
    await tester.pumpAndSettle();
    expect(service.lastCourse, _course);
    expect(find.byType(CourseRatingSummary), findsOneWidget);
    expect(find.text('评分分布'), findsOneWidget);
    expect(find.text('评分: 4.4 / 5'), findsOneWidget);
    expect(find.text('张老师 - $_course'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(service.keywords.last, '张老师');
    expect(service.keywords.length, 3);
    expect(find.text('张老师'), findsOneWidget);
  });

  testWidgets(
    'detail pagination retains whole course statistics and retries append failure',
    (tester) async {
      final service = _FakeService()..failSecondPage = true;
      final router = _router(detail: true);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(service, router));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('加载更多'));
      await tester.tap(find.text('加载更多'));
      await tester.pumpAndSettle();
      expect(find.text('first review'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      service.failSecondPage = false;
      await tester.ensureVisible(find.text('重试'));
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(service.pages, [1, 2, 2]);
      expect(service.summaryCalls, 1);
      expect(find.text('first review'), findsOneWidget);
      expect(find.text('second review'), findsOneWidget);
      expect(find.text('评分: 4.4 / 5'), findsOneWidget);
    },
  );

  testWidgets('late search response cannot overwrite a newer search', (
    tester,
  ) async {
    final service = _FakeService();
    final delayed = Completer<ApiResponse<PagedResult<CourseCommentSummary>>>();
    service.searchOverride = (keyword) async {
      if (keyword == 'slow') return delayed.future;
      return ApiResponse(data: _page([_summary], 1));
    };
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'slow');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'fast');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byType(CourseSummaryCard), findsOneWidget);
    delayed.complete(ApiResponse(data: _page(<CourseCommentSummary>[], 1)));
    await tester.pumpAndSettle();
    expect(find.byType(CourseSummaryCard), findsOneWidget);
    expect(find.text('fast'), findsOneWidget);
  });

  testWidgets('empty course shows no numerical zero score', (tester) async {
    final service = _FakeService()..empty = true;
    final router = _router(detail: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await tester.pumpAndSettle();
    expect(find.text('暂时没有已通过的评价。'), findsOneWidget);
    expect(find.byType(CourseRatingSummary), findsNothing);
    expect(find.textContaining('0.0 / 5'), findsNothing);
  });

  testWidgets('new review form prefills course but leaves teacher empty', (
    tester,
  ) async {
    final service = _FakeService();
    final router = _router(detail: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router, authenticated: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.plus_circle_fill));
    await tester.pumpAndSettle();
    final inputs = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(inputs[0].controller.text, isEmpty);
    expect(inputs[1].controller.text, _course);
    router.pop();
    await tester.pumpAndSettle();
  });
}

GoRouter _router({bool detail = false}) => GoRouter(
  initialLocation: detail
      ? Uri(
          path: '/teacher-comments/course',
          queryParameters: {'courseName': _course},
        ).toString()
      : '/teacher-comments',
  routes: [
    GoRoute(
      path: '/teacher-comments',
      builder: (context, state) => const TeacherCommentsScreen(),
    ),
    GoRoute(
      path: '/teacher-comments/course',
      builder: (context, state) => TeacherCommentsScreen(
        courseName: state.uri.queryParameters['courseName'],
      ),
    ),
  ],
);

Widget _app(
  _FakeService service,
  GoRouter router, {
  bool authenticated = false,
}) => ProviderScope(
  overrides: [
    teacherCommentServiceProvider.overrideWithValue(service),
    authControllerProvider.overrideWith(() => _FakeAuth(authenticated)),
  ],
  child: CupertinoApp.router(
    routerConfig: router,
    locale: const Locale('zh'),
    supportedLocales: const [Locale('zh')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => McThemeData.wrap(
      colors: McColors.light,
      locale: const Locale('zh'),
      child: child!,
    ),
  ),
);

class _FakeAuth extends AuthController {
  _FakeAuth(this.authenticated);
  final bool authenticated;
  @override
  Future<AuthState> build() async => authenticated
      ? AuthState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            user: UserDto(id: 'student', name: 'Student'),
          ),
        )
      : AuthState.unauthenticated();
}

PagedResult<T> _page<T>(List<T> items, int page, {bool hasMore = false}) =>
    PagedResult(
      items: items,
      totalCount: items.length,
      pageIndex: page,
      pageSize: 20,
      totalPages: hasMore ? 2 : page,
      hasPreviousPage: page > 1,
      hasNextPage: hasMore,
    );

class _FakeService extends TeacherCommentService {
  Future<ApiResponse<PagedResult<CourseCommentSummary>>> Function(String?)?
  searchOverride;
  final keywords = <String?>[];
  final pages = <int>[];
  int summaryCalls = 0;
  String? lastCourse;
  bool failSecondPage = false;
  bool empty = false;

  @override
  Future<ApiResponse<PagedResult<CourseCommentSummary>>> getCourses({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    keywords.add(keyword);
    if (searchOverride != null) return searchOverride!(keyword);
    return ApiResponse(data: _page([_summary], page));
  }

  @override
  Future<ApiResponse<CourseCommentSummary>> getCourseSummary(
    String courseName,
  ) async {
    summaryCalls++;
    lastCourse = courseName;
    return ApiResponse(
      data: empty
          ? const CourseCommentSummary(
              courseName: _course,
              totalCount: 0,
              averageStar: 0,
              starDistribution: [],
            )
          : _summary,
    );
  }

  @override
  Future<ApiResponse<PagedResult<TeacherCommentItem>>> getCourseComments(
    String courseName, {
    int page = 1,
    int pageSize = 20,
  }) async {
    pages.add(page);
    if (page == 2 && failSecondPage) throw StateError('append failed');
    return ApiResponse(
      data: _page(
        empty
            ? <TeacherCommentItem>[]
            : [
                TeacherCommentItem(
                  key: '$page',
                  teacherName: page == 1 ? '张老师' : '李老师',
                  courseName: courseName,
                  userId: 'student',
                  author: UserSimpleDto(id: 'student', name: 'Student'),
                  comment: page == 1 ? 'first review' : 'second review',
                  star: 5,
                  isReview: true,
                  createdOn: DateTime.utc(2026, 11, 1),
                ),
              ],
        page,
        hasMore: !empty && page == 1,
      ),
    );
  }
}

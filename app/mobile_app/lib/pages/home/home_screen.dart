import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luamris_ui/luamris_ui.dart';

import '../../components/hot_post_list.dart';
import '../../components/post_feed_list.dart';
import '../../l10n/app_localizations.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_tab_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../router/app_router.dart';
import '../../services/error_messages.dart';
import '../../ui/app_responsive.dart';
import 'widgets/home_tab_bar.dart';

/// Home page with Zhihu-style top tabs: 最新, 热榜 and one tab per active tag.
///
/// The three former pages (home feed, hot list and tag page) are rendered
/// inside a single scroll view; the selected tab lives in
/// [homeTabControllerProvider] so tag pills and notifications can jump here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();
  final Map<String, double> _scrollOffsets = {};
  late String _activeTabKey;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);

    final selected = ref.read(homeTabControllerProvider).selected;
    _activeTabKey = selected.key;
    _setSearchText(_keywordFor(selected));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  HomeTab get _selectedTab => ref.read(homeTabControllerProvider).selected;

  String _keywordFor(HomeTab tab) {
    return switch (tab.kind) {
      HomeTabKind.latest =>
        ref.read(homeFeedProvider).asData?.value.keyword ?? '',
      HomeTabKind.hot => '',
      HomeTabKind.tag => switch (tab.tagId) {
        final tagId? =>
          ref.read(tagFeedProvider(tagId)).asData?.value.keyword ?? '',
        null => '',
      },
    };
  }

  void _setSearchText(String text) {
    if (_searchController.text == text) return;
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleSelectionChanged(HomeTab next) {
    if (_scrollController.hasClients) {
      _scrollOffsets[_activeTabKey] = _scrollController.offset;
    }
    _activeTabKey = next.key;
    _setSearchText(_keywordFor(next));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final savedOffset = _scrollOffsets[next.key] ?? 0;
      final target = savedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      if ((_scrollController.offset - target).abs() > 0.5) {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 480) return;

    final tab = _selectedTab;
    switch (tab.kind) {
      case HomeTabKind.latest:
        unawaited(ref.read(homeFeedProvider.notifier).loadMore());
      case HomeTabKind.tag:
        final tagId = tab.tagId;
        if (tagId != null) {
          unawaited(ref.read(tagFeedProvider(tagId).notifier).loadMore());
        }
      case HomeTabKind.hot:
        break;
    }
  }

  Future<void> _refreshActiveTab() async {
    final tab = _selectedTab;
    switch (tab.kind) {
      case HomeTabKind.latest:
        await ref.read(homeFeedProvider.notifier).refresh();
      case HomeTabKind.hot:
        await ref.read(hotFeedProvider.notifier).refresh();
      case HomeTabKind.tag:
        final tagId = tab.tagId;
        if (tagId != null) {
          await ref.read(tagFeedProvider(tagId).notifier).refresh();
        }
    }
  }

  void _submitSearch(String value) {
    final keyword = value.trim();
    final tab = _selectedTab;
    switch (tab.kind) {
      case HomeTabKind.latest:
        unawaited(ref.read(homeFeedProvider.notifier).search(keyword));
      case HomeTabKind.tag:
        final tagId = tab.tagId;
        if (tagId != null) {
          unawaited(ref.read(tagFeedProvider(tagId).notifier).search(keyword));
        }
      case HomeTabKind.hot:
        break;
    }
  }

  void _handleSearchChanged(String value) {
    if (value.trim().isNotEmpty) return;

    final tab = _selectedTab;
    if (_keywordFor(tab).isEmpty) return;

    switch (tab.kind) {
      case HomeTabKind.latest:
        unawaited(ref.read(homeFeedProvider.notifier).clearSearch());
      case HomeTabKind.tag:
        final tagId = tab.tagId;
        if (tagId != null) {
          unawaited(ref.read(tagFeedProvider(tagId).notifier).clearSearch());
        }
      case HomeTabKind.hot:
        break;
    }
  }

  List<HomeTab> _buildTabs(List<PostTagDto> tags, HomeTabState selection) {
    final tagNamesById = <String, String?>{};
    for (final tag in tags) {
      tagNamesById[tag.id] = tag.name?.trim();
    }
    // Keep tabs opened from a post tag pill even when the tag list has not
    // loaded yet (or no longer contains that tag).
    for (final extra in selection.extraTags) {
      final tagId = extra.tagId;
      if (tagId == null) continue;
      tagNamesById.putIfAbsent(tagId, () => extra.tagName?.trim());
    }

    final tagTabs = [
      for (final entry in tagNamesById.entries)
        HomeTab.tag(tagId: entry.key, tagName: entry.value),
    ]..sort((a, b) => (a.tagName ?? '').compareTo(b.tagName ?? ''));

    return [const HomeTab.latest(), const HomeTab.hot(), ...tagTabs];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HomeTabState>(homeTabControllerProvider, (previous, next) {
      if (previous?.selected.key != next.selected.key) {
        _handleSelectionChanged(next.selected);
      }
    });
    ref.listen<NavigationRefreshEvent?>(navigationRefreshTargetProvider, (
      previous,
      next,
    ) {
      if (next != null &&
          next.index == 0 &&
          next.sequence != previous?.sequence) {
        unawaited(_refreshActiveTab());
      }
    });

    final l10n = AppLocalizations.of(context);
    final selection = ref.watch(homeTabControllerProvider);
    final selected = selection.selected;
    final tagsAsync = ref.watch(postTagsProvider);
    final tabs = _buildTabs(
      tagsAsync.asData?.value ?? const <PostTagDto>[],
      selection,
    );
    final authState = ref.watch(authControllerProvider).asData?.value;
    final isAuthenticated = authState?.status == AuthStatus.authenticated;

    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.tabHome),
            backgroundColor: context.mc.background.withValues(alpha: 0.94),
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (isAuthenticated) {
                  context.push(AppRoutePaths.createPost);
                } else {
                  context.go(AppRoutePaths.login);
                }
              },
              child: Icon(
                CupertinoIcons.plus_circle_fill,
                size: 28,
                color: context.mc.primary,
              ),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: _refreshActiveTab),
          SliverPersistentHeader(
            pinned: true,
            delegate: HomeTabBarHeaderDelegate(
              backgroundColor: context.mc.background.withValues(alpha: 0.98),
              child: HomeTabBar(
                key: const ValueKey('home-tab-bar'),
                tabs: tabs,
                selectedKey: selected.key,
                isLoadingTags: tagsAsync.isLoading && !tagsAsync.hasValue,
                hasTagError: tagsAsync.hasError,
                onRetryTags: () => ref.invalidate(postTagsProvider),
                onSelected: (tab) =>
                    ref.read(homeTabControllerProvider.notifier).select(tab),
              ),
            ),
          ),
          if (!selected.isHot) ...[
            SliverToBoxAdapter(
              child: AppResponsiveCenter(
                padding: AppResponsive.sliverPagePadding(
                  context,
                  top: 12,
                  bottom: 8,
                ),
                child: CupertinoSearchTextField(
                  key: const ValueKey('home-responsive-search-field'),
                  controller: _searchController,
                  placeholder: selected.isTag
                      ? l10n.tagSearchPlaceholder
                      : l10n.homeSearchPlaceholder,
                  borderRadius: BorderRadius.circular(McRadii.md),
                  backgroundColor: context.mc.secondary,
                  onSubmitted: _submitSearch,
                  onChanged: _handleSearchChanged,
                ),
              ),
            ),
          ],
          ..._buildFeedSlivers(context, selected),
        ],
      ),
    );
  }

  List<Widget> _buildFeedSlivers(BuildContext context, HomeTab selected) {
    switch (selected.kind) {
      case HomeTabKind.latest:
        final feedAsync = ref.watch(homeFeedProvider);
        return feedAsync.when(
          data: (state) => _buildPostListSlivers(
            context,
            state: state,
            isTagTab: false,
            emptyIcon: state.keyword.isEmpty
                ? CupertinoIcons.news
                : CupertinoIcons.search,
            emptyTitle: state.keyword.isEmpty
                ? AppLocalizations.of(context).homeEmpty
                : AppLocalizations.of(context).homeNoSearchResults,
            emptyDescription: state.keyword.isEmpty
                ? AppLocalizations.of(context).waitFirstPoster
                : AppLocalizations.of(context).tryDifferentKeyword,
          ),
          loading: () => [_loadingSliver()],
          error: (error, _) => [
            _errorSliver(
              context,
              message: extractErrorFromException(error),
              onRetry: () => ref.read(homeFeedProvider.notifier).refresh(),
            ),
          ],
        );

      case HomeTabKind.hot:
        final feedAsync = ref.watch(hotFeedProvider);
        return feedAsync.when(
          data: (state) => state.posts.isEmpty
              ? [
                  _emptySliver(
                    icon: CupertinoIcons.flame,
                    title: AppLocalizations.of(context).hotListEmpty,
                    description: AppLocalizations.of(context).hotListEmptyDesc,
                  ),
                ]
              : [
                  AppResponsiveSliverPadding(
                    child: HotPostList(posts: state.posts),
                  ),
                ],
          loading: () => [_loadingSliver()],
          error: (error, _) => [
            _errorSliver(
              context,
              message: extractErrorFromException(error),
              onRetry: () => ref.read(hotFeedProvider.notifier).refresh(),
            ),
          ],
        );

      case HomeTabKind.tag:
        final tagId = selected.tagId;
        if (tagId == null) {
          return [
            _emptySliver(
              icon: CupertinoIcons.tag,
              title: AppLocalizations.of(context).postTagEmpty,
              description: AppLocalizations.of(context).tagNoPostsDesc,
            ),
          ];
        }
        final feedAsync = ref.watch(tagFeedProvider(tagId));
        return feedAsync.when(
          data: (state) => _buildPostListSlivers(
            context,
            state: state,
            isTagTab: true,
            emptyIcon: state.keyword.isEmpty
                ? CupertinoIcons.tag
                : CupertinoIcons.search,
            emptyTitle: state.keyword.isEmpty
                ? AppLocalizations.of(context).postTagEmpty
                : AppLocalizations.of(context).homeNoSearchResults,
            emptyDescription: state.keyword.isEmpty
                ? AppLocalizations.of(context).tagNoPostsDesc
                : AppLocalizations.of(context).tagNoSearchResultsDesc,
          ),
          loading: () => [_loadingSliver()],
          error: (error, _) => [
            _errorSliver(
              context,
              message: extractErrorFromException(error),
              onRetry: () =>
                  ref.read(tagFeedProvider(tagId).notifier).refresh(),
            ),
          ],
        );
    }
  }

  List<Widget> _buildPostListSlivers(
    BuildContext context, {
    required HomeFeedState state,
    required bool isTagTab,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyDescription,
  }) {
    final l10n = AppLocalizations.of(context);

    if (state.posts.isEmpty && state.isRefreshing) {
      return [_loadingSliver()];
    }

    if (state.posts.isEmpty) {
      return [
        _emptySliver(
          icon: emptyIcon,
          title: emptyTitle,
          description: emptyDescription,
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: AppResponsiveCenter(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: _SearchLoadingIndicator(
            isVisible: state.isRefreshing,
            label: state.keyword.isEmpty
                ? (isTagTab ? l10n.tagRefreshingPosts : l10n.refreshingPosts)
                : (isTagTab ? l10n.tagSearching : l10n.searching),
          ),
        ),
      ),
      AppResponsiveSliverPadding(
        child: PostFeedList(
          posts: state.posts,
          isLoadingMore: state.isLoadingMore,
          keyPrefix: isTagTab ? 'tag-feed' : 'home-feed',
        ),
      ),
    ];
  }

  Widget _loadingSliver() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CupertinoActivityIndicator(radius: 14)),
    );
  }

  Widget _emptySliver({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: McEmpty.placeholder(
            icon: icon,
            title: title,
            description: description,
          ),
        ),
      ),
    );
  }

  Widget _errorSliver(
    BuildContext context, {
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: McEmpty.placeholder(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: AppLocalizations.of(context).loadingFailed,
            description: message,
            action: McButton.primary(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchLoadingIndicator extends StatelessWidget {
  const _SearchLoadingIndicator({required this.isVisible, required this.label});

  final bool isVisible;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CupertinoActivityIndicator(radius: 8),
        const SizedBox(width: 8),
        Text(label, style: context.mc.textLabel),
      ],
    );
  }
}

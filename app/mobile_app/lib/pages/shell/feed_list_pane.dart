import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luamris_ui/luamris_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/desktop_detail_provider.dart';
import '../../providers/home_tab_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../router/app_router.dart';
import '../../services/error_messages.dart';
import '../home/widgets/home_tab_bar.dart';
import 'compact_post_tile.dart';

/// List column of the desktop shell: home top tabs, search and the compact
/// post feed (latest / hot / tag).
///
/// Tapping a row selects the post in the right-hand detail column instead of
/// pushing a new route, so the three-column layout stays in place.
class FeedListPane extends ConsumerStatefulWidget {
  const FeedListPane({super.key});

  @override
  ConsumerState<FeedListPane> createState() => _FeedListPaneState();
}

class _FeedListPaneState extends ConsumerState<FeedListPane> {
  late final ScrollController _scrollController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    final selected = ref.read(homeTabControllerProvider).selected;
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

  void _openComposer(bool isAuthenticated) {
    if (isAuthenticated) {
      context.push(AppRoutePaths.createPost);
    } else {
      context.go(AppRoutePaths.login);
    }
  }

  void _selectPost(PostDto post) {
    ref.read(desktopDetailProvider.notifier).select(post.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HomeTabState>(homeTabControllerProvider, (previous, next) {
      if (previous?.selected.key == next.selected.key) return;
      _setSearchText(_keywordFor(next.selected));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
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
    final selectedPostId = ref.watch(desktopDetailProvider);

    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tabHome,
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
                    onPressed: () => _openComposer(isAuthenticated),
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
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.mc.border.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: HomeTabBar(
              key: const ValueKey('desktop-home-tab-bar'),
              tabs: tabs,
              selectedKey: selected.key,
              isLoadingTags: tagsAsync.isLoading && !tagsAsync.hasValue,
              hasTagError: tagsAsync.hasError,
              onRetryTags: () => ref.invalidate(postTagsProvider),
              onSelected: (tab) =>
                  ref.read(homeTabControllerProvider.notifier).select(tab),
            ),
          ),
          if (!selected.isHot)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: CupertinoSearchTextField(
                key: const ValueKey('desktop-feed-search-field'),
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
          Expanded(
            child: _buildFeed(
              context,
              selected: selected,
              selectedPostId: selectedPostId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(
    BuildContext context, {
    required HomeTab selected,
    required String? selectedPostId,
  }) {
    switch (selected.kind) {
      case HomeTabKind.latest:
        final feedAsync = ref.watch(homeFeedProvider);
        return feedAsync.when(
          data: (state) => state.posts.isEmpty && state.isRefreshing
              ? _loadingView()
              : state.posts.isEmpty
              ? _emptyView(
                  icon: state.keyword.isEmpty
                      ? CupertinoIcons.news
                      : CupertinoIcons.search,
                  title: state.keyword.isEmpty
                      ? AppLocalizations.of(context).homeEmpty
                      : AppLocalizations.of(context).homeNoSearchResults,
                  description: state.keyword.isEmpty
                      ? AppLocalizations.of(context).waitFirstPoster
                      : AppLocalizations.of(context).tryDifferentKeyword,
                )
              : _listView(
                  posts: state.posts,
                  isLoadingMore: state.isLoadingMore,
                  selectedPostId: selectedPostId,
                ),
          loading: _loadingView,
          error: (error, _) => _errorView(
            context,
            message: extractErrorFromException(error),
            onRetry: () => ref.read(homeFeedProvider.notifier).refresh(),
          ),
        );

      case HomeTabKind.hot:
        // [hotFeedProvider] wraps `postService.getHotPosts`, so the desktop
        // pane and the mobile hot tab share the same request.
        final feedAsync = ref.watch(hotFeedProvider);
        return feedAsync.when(
          data: (state) => state.posts.isEmpty
              ? _emptyView(
                  icon: CupertinoIcons.flame,
                  title: AppLocalizations.of(context).hotListEmpty,
                  description: AppLocalizations.of(context).hotListEmptyDesc,
                )
              : _listView(
                  posts: state.posts,
                  isLoadingMore: false,
                  selectedPostId: selectedPostId,
                  ranked: true,
                ),
          loading: _loadingView,
          error: (error, _) => _errorView(
            context,
            message: extractErrorFromException(error),
            onRetry: () => ref.read(hotFeedProvider.notifier).refresh(),
          ),
        );

      case HomeTabKind.tag:
        final tagId = selected.tagId;
        if (tagId == null) {
          return _emptyView(
            icon: CupertinoIcons.tag,
            title: AppLocalizations.of(context).postTagEmpty,
            description: AppLocalizations.of(context).tagNoPostsDesc,
          );
        }
        final feedAsync = ref.watch(tagFeedProvider(tagId));
        return feedAsync.when(
          data: (state) => state.posts.isEmpty && state.isRefreshing
              ? _loadingView()
              : state.posts.isEmpty
              ? _emptyView(
                  icon: state.keyword.isEmpty
                      ? CupertinoIcons.tag
                      : CupertinoIcons.search,
                  title: state.keyword.isEmpty
                      ? AppLocalizations.of(context).postTagEmpty
                      : AppLocalizations.of(context).homeNoSearchResults,
                  description: state.keyword.isEmpty
                      ? AppLocalizations.of(context).tagNoPostsDesc
                      : AppLocalizations.of(context).tagNoSearchResultsDesc,
                )
              : _listView(
                  posts: state.posts,
                  isLoadingMore: state.isLoadingMore,
                  selectedPostId: selectedPostId,
                ),
          loading: _loadingView,
          error: (error, _) => _errorView(
            context,
            message: extractErrorFromException(error),
            onRetry: () =>
                ref.read(tagFeedProvider(tagId).notifier).refresh(),
          ),
        );
    }
  }

  Widget _listView({
    required List<PostDto> posts,
    required bool isLoadingMore,
    required String? selectedPostId,
    bool ranked = false,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refreshActiveTab),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          sliver: SliverList.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return CompactPostTile(
                post: post,
                isSelected: post.id == selectedPostId,
                rank: ranked ? index + 1 : null,
                onTap: () => _selectPost(post),
              );
            },
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _loadingView() {
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator(radius: 14)),
        ),
      ],
    );
  }

  Widget _emptyView({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refreshActiveTab),
        SliverFillRemaining(
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
        ),
      ],
    );
  }

  Widget _errorView(
    BuildContext context, {
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refreshActiveTab),
        SliverFillRemaining(
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
        ),
      ],
    );
  }
}

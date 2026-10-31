import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/desktop_detail_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/post_feed_provider.dart';
import '../ui/app_responsive.dart';
import 'post/post_detail_screen.dart';
import 'shell/desktop_welcome_pane.dart';

/// Width of the icon-only rail in the three-column desktop layout.
const double _desktopRailWidth = 76;

/// Width of the icon rail in the tablet layout.
const double _tabletRailWidth = 88;

/// Width of the compact list column in the desktop layout.
const double _desktopListWidth = 340;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _exitWindow = Duration(seconds: 2);
  Timer? _unreadRefreshTimer;

  DateTime? _lastExitAttemptAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unreadRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
    }
  }

  void _onTap(BuildContext context, int index) {
    if (index != widget.navigationShell.currentIndex) {
      _lastExitAttemptAt = null;
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // Branches are kept alive by StatefulShellRoute, so explicitly signal
    // the selected screen to reload its data when it becomes visible again.
    ref.read(navigationRefreshTargetProvider.notifier).setTarget(index);
    if (index == 2) {
      unawaited(ref.read(unreadNotificationCountProvider.notifier).refresh());
    }
  }

  void _handleHomeExitAttempt() {
    final now = DateTime.now();
    final lastExitAttemptAt = _lastExitAttemptAt;

    if (lastExitAttemptAt != null &&
        now.difference(lastExitAttemptAt) <= _exitWindow) {
      unawaited(SystemNavigator.pop());
      return;
    }

    _lastExitAttemptAt = now;
    ref.read(navigationRefreshTargetProvider.notifier).setTarget(0);
    unawaited(
      McFeedback.showInfo(
        context,
        message: AppLocalizations.of(context).nextExit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);
    final isTablet = AppResponsive.isTablet(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final shouldInterceptExit =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final currentIndex = widget.navigationShell.currentIndex;
    final detailPostId = ref.watch(desktopDetailProvider);

    final Widget content;
    if (isDesktop) {
      // WeChat-style three-column layout: icon rail, compact list and detail.
      // Branch 3 (profile / settings) intentionally degrades to two columns so
      // settings pages keep their full width.
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideNavigation(
            key: const ValueKey('main-shell-desktop-rail'),
            width: _desktopRailWidth,
            horizontalPadding: 6,
            drawRightBorder: false,
            currentIndex: currentIndex,
            hasUnreadNotifications: unreadCount > 0,
            onTap: (index) => _onTap(context, index),
          ),
          const _VerticalDivider(),
          if (currentIndex == 3)
            Expanded(child: widget.navigationShell)
          else ...[
            SizedBox(width: _desktopListWidth, child: widget.navigationShell),
            const _VerticalDivider(),
            Expanded(
              child: detailPostId == null
                  ? DesktopWelcomePane(
                      onSelectBranch: (index) => _onTap(context, index),
                    )
                  : PostDetailScreen(
                      // Remount when the selected post changes so the detail
                      // screen reloads instead of keeping the previous post.
                      key: ValueKey('desktop-detail-$detailPostId'),
                      postId: detailPostId,
                      embedded: true,
                    ),
            ),
          ],
        ],
      );
    } else if (isTablet) {
      content = Row(
        children: [
          _SideNavigation(
            key: const ValueKey('main-shell-tablet-side-navigation'),
            width: _tabletRailWidth,
            horizontalPadding: 8,
            currentIndex: currentIndex,
            hasUnreadNotifications: unreadCount > 0,
            onTap: (index) => _onTap(context, index),
          ),
          Expanded(child: widget.navigationShell),
        ],
      );
    } else {
      content = Column(
        children: [
          Expanded(child: widget.navigationShell),
          CupertinoTabBar(
            backgroundColor: context.mc.background.withValues(alpha: 0.8),
            activeColor: context.mc.primary,
            inactiveColor: context.mc.secondaryLabel.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: context.mc.border.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            currentIndex: currentIndex,
            onTap: (index) => _onTap(context, index),
            items: _navigationItems(context).indexed
                .map(
                  (entry) => BottomNavigationBarItem(
                    icon: _navigationIcon(
                      context,
                      entry.$2.icon,
                      hasUnread: entry.$1 == 2 && unreadCount > 0,
                    ),
                    activeIcon: _navigationIcon(
                      context,
                      entry.$2.activeIcon,
                      hasUnread: entry.$1 == 2 && unreadCount > 0,
                    ),
                    label: entry.$2.label,
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    final scaffold = CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: content,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Desktop detail column takes priority over branch navigation.
        if (ref.read(desktopDetailProvider) != null) {
          ref.read(desktopDetailProvider.notifier).clear();
          return;
        }

        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
          return;
        }

        if (shouldInterceptExit) {
          _handleHomeExitAttempt();
        }
      },
      child: scaffold,
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      color: context.mc.border.withValues(alpha: 0.3),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    super.key,
    required this.width,
    required this.horizontalPadding,
    this.drawRightBorder = true,
    required this.currentIndex,
    required this.hasUnreadNotifications,
    required this.onTap,
  });

  final double width;
  final double horizontalPadding;
  final bool drawRightBorder;
  final int currentIndex;
  final bool hasUnreadNotifications;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.mc.background;
    final borderColor = context.mc.border;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.92),
        border: drawRightBorder
            ? Border(
                right: BorderSide(
                  color: borderColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: horizontalPadding,
          ),
          child: Column(
            children: [
              for (final entry in _navigationItems(context).indexed)
                _SideNavigationItem(
                  item: entry.$2,
                  isSelected: entry.$1 == currentIndex,
                  hasUnread: entry.$1 == 2 && hasUnreadNotifications,
                  onPressed: () => onTap(entry.$1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavigationItem extends StatelessWidget {
  const _SideNavigationItem({
    required this.item,
    required this.isSelected,
    required this.hasUnread,
    required this.onPressed,
  });

  static const double _height = 52;

  final _MainNavigationItem item;
  final bool isSelected;
  final bool hasUnread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? context.mc.primary
        : context.mc.secondaryLabel.withValues(alpha: 0.8);
    final Color? backgroundColor = isSelected
        ? context.mc.primary.withValues(alpha: 0.12)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(McRadii.md),
        onPressed: onPressed,
        child: Container(
          height: _height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(McRadii.md),
          ),
          // The rail entry has a fixed height, so clamp the label scale
          // instead of overflowing when the system text size is enlarged.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _navigationIcon(
                  context,
                  isSelected ? item.activeIcon : item.icon,
                  hasUnread: hasUnread,
                  color: foregroundColor,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
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

Widget _navigationIcon(
  BuildContext context,
  IconData icon, {
  required bool hasUnread,
  Color? color,
  double size = 24,
}) {
  final iconWidget = Icon(icon, color: color, size: size);
  if (!hasUnread) return iconWidget;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      iconWidget,
      Positioned(
        right: -4,
        top: -3,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: context.mc.destructive,
            shape: BoxShape.circle,
            border: Border.all(color: context.mc.background, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _MainNavigationItem {
  const _MainNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

List<_MainNavigationItem> _navigationItems(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    _MainNavigationItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: l10n.tabHome,
    ),
    _MainNavigationItem(
      icon: CupertinoIcons.book,
      activeIcon: CupertinoIcons.book_fill,
      label: l10n.tabTeacherComments,
    ),
    _MainNavigationItem(
      icon: CupertinoIcons.bell,
      activeIcon: CupertinoIcons.bell_fill,
      label: l10n.tabNotifications,
    ),
    _MainNavigationItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: l10n.tabProfile,
    ),
  ];
}

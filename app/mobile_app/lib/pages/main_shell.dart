import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_provider.dart';
import '../providers/post_feed_provider.dart';
import '../ui/app_responsive.dart';

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
    final isTablet = AppResponsive.isTablet(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final shouldInterceptExit =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    final scaffold = CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: isTablet
          ? Row(
              children: [
                _TabletSideNavigation(
                  currentIndex: widget.navigationShell.currentIndex,
                  hasUnreadNotifications: unreadCount > 0,
                  onTap: (index) => _onTap(context, index),
                ),
                Expanded(child: widget.navigationShell),
              ],
            )
          : Column(
              children: [
                Expanded(child: widget.navigationShell),
                CupertinoTabBar(
                  backgroundColor: context.mc.background.withValues(alpha: 0.8),
                  activeColor: context.mc.primary,
                  inactiveColor: context.mc.secondaryLabel.withValues(
                    alpha: 0.8,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: context.mc.border.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  currentIndex: widget.navigationShell.currentIndex,
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
            ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

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

class _TabletSideNavigation extends StatelessWidget {
  const _TabletSideNavigation({
    required this.currentIndex,
    required this.hasUnreadNotifications,
    required this.onTap,
  });

  final int currentIndex;
  final bool hasUnreadNotifications;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.mc.background;
    final borderColor = context.mc.border;

    return Container(
      key: const ValueKey('main-shell-tablet-side-navigation'),
      width: 104,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.92),
        border: Border(
          right: BorderSide(
            color: borderColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            children: [
              for (final entry in _navigationItems(context).indexed)
                _TabletSideNavigationItem(
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

class _TabletSideNavigationItem extends StatelessWidget {
  const _TabletSideNavigationItem({
    required this.item,
    required this.isSelected,
    required this.hasUnread,
    required this.onPressed,
  });

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
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(McRadii.md),
        onPressed: onPressed,
        child: Container(
          height: 64,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(McRadii.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navigationIcon(
                context,
                isSelected ? item.activeIcon : item.icon,
                hasUnread: hasUnread,
                color: foregroundColor,
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
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

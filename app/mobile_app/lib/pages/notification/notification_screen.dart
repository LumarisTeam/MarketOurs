import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luamris_ui/luamris_ui.dart';

import 'package:mobile_app/l10n/app_localizations.dart';

import '../../models/notification.dart';
import '../../providers/desktop_detail_provider.dart';
import '../../providers/home_tab_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../router/app_router.dart';
import '../../services/notification_service.dart';
import '../../ui/app_responsive.dart';
import '../../utils/date_formatters.dart';
import '../shell/compact_notification_tile.dart';
import 'push_settings_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final NotificationService service;

  const NotificationScreen({super.key, required this.service});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

enum _NotificationCategory { all, comments, reviews, other }

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  List<NotificationDto> _notifications = [];
  bool _isLoading = true;
  Locale? _lastLocale;
  _NotificationCategory _category = _NotificationCategory.all;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale != null && _lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      _loadNotifications();
    } else if (_lastLocale == null) {
      _lastLocale = currentLocale;
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.service.getNotifications();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _notifications = result.items;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NotificationDto> get _visibleNotifications {
    return switch (_category) {
      _NotificationCategory.all => _notifications,
      _NotificationCategory.comments =>
        _notifications
            .where(
              (n) =>
                  n.type == NotificationType.commentReply ||
                  n.type == NotificationType.postReply,
            )
            .toList(),
      _NotificationCategory.reviews =>
        _notifications.where((n) => n.type == NotificationType.review).toList(),
      _NotificationCategory.other =>
        _notifications
            .where(
              (n) =>
                  n.type == NotificationType.hotList ||
                  n.type == NotificationType.system ||
                  n.type == NotificationType.unknown,
            )
            .toList(),
    };
  }

  IconData _getIcon(NotificationType type) => notificationIconForType(type);

  Color _getIconColor(BuildContext context, NotificationType type) =>
      notificationIconColorForType(context, type);

  @override
  Widget build(BuildContext context) {
    ref.listen<NavigationRefreshEvent?>(navigationRefreshTargetProvider, (
      _,
      event,
    ) {
      if (event?.index == 2 && mounted) unawaited(_loadNotifications());
    });
    final l10n = AppLocalizations.of(context);
    final isDesktop = AppResponsive.isDesktop(context);
    final visibleNotifications = _visibleNotifications;

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_notifications.any((n) => !n.isRead)) ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () async {
              await _markAllAsReadOptimistically();
            },
            child: const Icon(CupertinoIcons.trash, size: 24),
          ),
          const SizedBox(width: 20),
        ],
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => PushSettingsScreen(service: widget.service),
              ),
            );
          },
          child: const Icon(CupertinoIcons.settings, size: 24),
        ),
      ],
    );

    final categorySelector =
        CupertinoSlidingSegmentedControl<_NotificationCategory>(
          groupValue: _category,
          children: {
            _NotificationCategory.all: Text(l10n.tabNotifications),
            _NotificationCategory.comments: Text(
              l10n.notificationTypePostReplyTitle,
            ),
            _NotificationCategory.reviews: Text(
              l10n.notificationTypeReviewTitle,
            ),
            _NotificationCategory.other: Text(
              l10n.notificationTypeSystemTitle,
            ),
          },
          onValueChanged: (value) {
            if (value != null && mounted) {
              setState(() => _category = value);
            }
          },
        );

    final Widget listSliver;
    if (_isLoading && visibleNotifications.isEmpty) {
      listSliver = const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    } else if (visibleNotifications.isEmpty) {
      listSliver = SliverFillRemaining(child: _buildEmptyState());
    } else if (isDesktop) {
      // Desktop: compact single-line rows inside the 340px list column.
      listSliver = SliverPadding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        sliver: SliverList.builder(
          itemCount: visibleNotifications.length,
          itemBuilder: (context, index) {
            final notification = visibleNotifications[index];
            return CompactNotificationTile(
              notification: notification,
              onTap: () {
                unawaited(_openNotification(notification));
              },
            );
          },
        ),
      );
    } else {
      listSliver = AppResponsiveSliverPadding(
        child: _NotificationList(
          notifications: visibleNotifications,
          iconForType: _getIcon,
          iconColorForType: _getIconColor,
          formatDate: (date, context) => formatNotificationDateTime(
            date,
            AppLocalizations.of(context),
          ),
          onOpen: _openNotification,
          onOpenPost: _openPost,
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: context.mc.background,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (isDesktop)
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.tabNotifications,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.mc.foreground,
                            ),
                          ),
                        ),
                        actions,
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            CupertinoSliverNavigationBar(
              largeTitle: Text(l10n.tabNotifications),
              backgroundColor: context.mc.background.withValues(alpha: 0.94),
              border: null,
              trailing: actions,
            ),
          CupertinoSliverRefreshControl(onRefresh: _loadNotifications),
          SliverToBoxAdapter(
            child: isDesktop
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: 420, child: categorySelector),
                    ),
                  )
                : AppResponsiveCenter(
                    padding: AppResponsive.sliverPagePadding(
                      context,
                      top: 8,
                      bottom: 8,
                    ),
                    child: categorySelector,
                  ),
          ),
          listSliver,
        ],
      ),
    );
  }

  void _openPost(String postId) {
    if (AppResponsive.isDesktop(context)) {
      ref.read(desktopDetailProvider.notifier).select(postId);
      return;
    }
    context.push(buildPostDetailLocation(postId));
  }

  Future<void> _openNotification(NotificationDto n) async {
    final index = _notifications.indexWhere((item) => item.id == n.id);
    if (index < 0) return;
    if (!n.isRead) {
      setState(() {
        _notifications[index] = _copyNotification(n, isRead: true);
      });
      widget.service
          .markAsRead(n.id)
          .then((success) {
            if (success) {
              unawaited(
                ref.read(unreadNotificationCountProvider.notifier).refresh(),
              );
            } else if (mounted) {
              _loadNotifications();
            }
          })
          .catchError((_) {
            if (mounted) _loadNotifications();
          });
    }

    if (!mounted) {
      return;
    }

    final params = n.typedParams;
    if (n.type == NotificationType.hotList) {
      ref.read(homeTabControllerProvider.notifier).selectHot();
      context.go(AppRoutePaths.home);
    } else if (params is ReviewParams &&
        params.entityType == 'teacherComment') {
      return;
    } else if (n.targetId?.isNotEmpty == true) {
      _openPost(n.targetId!);
    }
  }

  Future<void> _markAllAsReadOptimistically() async {
    final previous = _notifications;
    setState(() {
      _notifications = [
        for (final n in _notifications) _copyNotification(n, isRead: true),
      ];
    });

    try {
      final success = await widget.service.markAllAsRead();
      if (success) {
        ref.read(unreadNotificationCountProvider.notifier).clear();
      } else if (mounted) {
        setState(() => _notifications = previous);
      }
    } catch (_) {
      if (mounted) setState(() => _notifications = previous);
    }
  }

  NotificationDto _copyNotification(NotificationDto n, {required bool isRead}) {
    return NotificationDto(
      id: n.id,
      userId: n.userId,
      title: n.title,
      content: n.content,
      type: n.type,
      targetId: n.targetId,
      isRead: isRead,
      createdAt: n.createdAt,
      params: n.params,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.mc.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.bell_slash,
              size: 32,
              color: context.mc.secondaryLabel,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).notificationEmpty,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.mc.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notifications,
    required this.iconForType,
    required this.iconColorForType,
    required this.formatDate,
    required this.onOpen,
    required this.onOpenPost,
  });

  final List<NotificationDto> notifications;
  final IconData Function(NotificationType type) iconForType;
  final Color Function(BuildContext context, NotificationType type)
  iconColorForType;
  final String Function(DateTime? date, BuildContext context) formatDate;
  final Future<void> Function(NotificationDto notification) onOpen;
  final ValueChanged<String> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final columns = AppResponsive.listColumnCount(context);
    if (columns == 1) {
      return Column(
        key: const ValueKey('notification-list-columns-1'),
        children: [
          for (final entry in notifications.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationCard(
                notification: entry.$2,
                icon: iconForType(entry.$2.type),
                iconColor: iconColorForType(context, entry.$2.type),
                formattedDate: formatDate(entry.$2.createdAt, context),
                onOpenPost: onOpenPost,
                onPressed: () {
                  onOpen(entry.$2);
                },
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      key: const ValueKey('notification-list-columns-2'),
      builder: (context, constraints) {
        const spacing = 16.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in notifications.indexed)
              SizedBox(
                width: itemWidth,
                child: _NotificationCard(
                  notification: entry.$2,
                  icon: iconForType(entry.$2.type),
                  iconColor: iconColorForType(context, entry.$2.type),
                  formattedDate: formatDate(entry.$2.createdAt, context),
                  onOpenPost: onOpenPost,
                  onPressed: () {
                    onOpen(entry.$2);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.formattedDate,
    required this.onPressed,
    required this.onOpenPost,
  });

  final NotificationDto notification;
  final IconData icon;
  final Color iconColor;
  final String formattedDate;
  final VoidCallback onPressed;
  final ValueChanged<String> onOpenPost;

  @override
  Widget build(BuildContext context) {
    return McCard.elevated(
      padding: const EdgeInsets.all(16),
      onPressed: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _NotificationTitle(
                        type: notification.type,
                        isRead: notification.isRead,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.mc.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _NotificationBodyV2(
                  params: notification.typedParams,
                  content: notification.content,
                  type: notification.type,
                  onPostTap: onOpenPost,
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: context.mc.textLabel.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTitle extends StatelessWidget {
  const _NotificationTitle({required this.type, required this.isRead});

  final NotificationType type;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final title = notificationTitleForType(loc, type);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
        color: context.mc.foreground,
      ),
    );
  }
}

class _NotificationBodyV2 extends StatelessWidget {
  const _NotificationBodyV2({
    required this.params,
    required this.content,
    required this.type,
    required this.onPostTap,
  });

  final NotificationParams? params;
  final String content;
  final NotificationType type;
  final ValueChanged<String> onPostTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final p = params;

    switch (type) {
      case NotificationType.commentReply:
        if (p is CommentReplyParams) {
          return _plainText(
            loc.notificationTypeCommentReplyContent(
              p.commenterName,
              p.bodySnippet,
            ),
            context,
          );
        }
        return _plainText(content, context);

      case NotificationType.postReply:
        if (p is PostReplyParams) {
          return _plainText(
            loc.notificationTypePostReplyContent(
              p.commenterName,
              p.bodySnippet,
            ),
            context,
          );
        }
        return _plainText(content, context);

      case NotificationType.hotList:
        final header = loc.notificationTypeHotListHeader;
        if (p is HotListParams && p.posts.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                header,
                style: context.mc.textMuted.copyWith(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 4),
              for (final post in p.posts)
                _HotPostLine(
                  title: post.title,
                  onTap: () => onPostTap(post.id),
                ),
            ],
          );
        }
        return _plainText(content, context);

      case NotificationType.review:
        if (p is ReviewParams) {
          final entity = switch (p.entityType) {
            'post' => loc.notificationTypeReviewEntityPost,
            'teacherComment' => loc.notificationTypeReviewEntityTeacherComment,
            _ => loc.notificationTypeReviewEntityComment,
          };
          if (p.approved) {
            return _plainText(
              loc.notificationTypeReviewApproved(entity, p.name),
              context,
            );
          }
          return _plainText(
            loc.notificationTypeReviewRejected(entity, p.name, p.reason ?? ''),
            context,
          );
        }
        return _plainText(content, context);

      default:
        return _plainText(content, context);
    }
  }

  Widget _plainText(String text, BuildContext context) {
    return Text(
      text,
      style: context.mc.textMuted.copyWith(fontSize: 14, height: 1.4),
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _HotPostLine extends StatelessWidget {
  const _HotPostLine({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: context.mc.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

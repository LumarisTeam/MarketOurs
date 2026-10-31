import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../../models/notification.dart';
import '../../utils/date_formatters.dart';

/// Icon used for a notification kind, shared by the full page and the desktop
/// compact row.
IconData notificationIconForType(NotificationType type) {
  return switch (type) {
    NotificationType.commentReply => CupertinoIcons.reply,
    NotificationType.postReply => CupertinoIcons.chat_bubble_2,
    NotificationType.hotList => CupertinoIcons.flame,
    NotificationType.system => CupertinoIcons.bell,
    NotificationType.review => CupertinoIcons.check_mark_circled,
    NotificationType.unknown => CupertinoIcons.bell,
  };
}

Color notificationIconColorForType(BuildContext context, NotificationType type) {
  return switch (type) {
    NotificationType.commentReply => context.mc.primary,
    NotificationType.postReply => context.mc.success,
    NotificationType.hotList => context.mc.warning,
    NotificationType.system => context.mc.secondaryLabel,
    NotificationType.review => context.mc.purple,
    NotificationType.unknown => context.mc.secondaryLabel,
  };
}

String notificationTitleForType(
  AppLocalizations l10n,
  NotificationType type,
) {
  return switch (type) {
    NotificationType.commentReply => l10n.notificationTypeCommentReplyTitle,
    NotificationType.postReply => l10n.notificationTypePostReplyTitle,
    NotificationType.hotList => l10n.notificationTypeHotListTitle,
    NotificationType.review => l10n.notificationTypeReviewTitle,
    NotificationType.system => l10n.notificationTypeSystemTitle,
    NotificationType.unknown => l10n.tabNotifications,
  };
}

/// Single-line notification row used by the desktop list column.
class CompactNotificationTile extends StatelessWidget {
  const CompactNotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationDto notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iconColor = notificationIconColorForType(context, notification.type);
    final title = notificationTitleForType(l10n, notification.type);
    final body = notification.content.trim();
    final time = formatNotificationDateTime(notification.createdAt, l10n);
    final isUnread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(McRadii.md),
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isUnread
                ? context.mc.primary.withValues(alpha: 0.06)
                : null,
            borderRadius: BorderRadius.circular(McRadii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificationIconForType(notification.type),
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: context.mc.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: context.mc.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: context.mc.secondaryLabel,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.mc.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

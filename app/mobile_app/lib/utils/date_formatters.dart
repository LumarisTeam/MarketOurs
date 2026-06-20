import '../l10n/app_localizations.dart';

DateTime? _toLocalDateTime(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.isUtc ? dateTime.toLocal() : dateTime;
}

bool isEdited(
  DateTime? createdAt,
  DateTime? updatedAt, {
  Duration threshold = const Duration(seconds: 5),
}) {
  final localCreatedAt = _toLocalDateTime(createdAt);
  final localUpdatedAt = _toLocalDateTime(updatedAt);
  if (localCreatedAt == null || localUpdatedAt == null) return false;
  return localUpdatedAt.difference(localCreatedAt) > threshold;
}

String formatRelativeDateTime(DateTime? dateTime, [AppLocalizations? l10n]) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return l10n?.dateJustNow ?? '刚刚';

  final diff = DateTime.now().difference(localDateTime);
  if (diff.inMinutes < 1) return l10n?.dateJustNow ?? '刚刚';
  if (diff.inHours < 1) {
    return l10n?.dateMinutesAgo(diff.inMinutes) ?? '${diff.inMinutes}分钟前';
  }
  if (diff.inDays < 1) {
    return l10n?.dateHoursAgo(diff.inHours) ?? '${diff.inHours}小时前';
  }
  if (diff.inDays < 7) {
    return l10n?.dateDaysAgo(diff.inDays) ?? '${diff.inDays}天前';
  }
  return formatYmdDate(localDateTime);
}

String formatEditedRelativeDateTime(
  DateTime? createdAt,
  DateTime? updatedAt, {
  AppLocalizations? l10n,
  String editedLabel = '已编辑',
}) {
  final relative = formatRelativeDateTime(createdAt, l10n);
  if (!isEdited(createdAt, updatedAt)) {
    return relative;
  }

  return '$relative ($editedLabel)';
}

String formatYmdDate(DateTime? dateTime, {String separator = '-'}) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return '';
  final month = localDateTime.month.toString().padLeft(2, '0');
  final day = localDateTime.day.toString().padLeft(2, '0');
  return '${localDateTime.year}$separator$month$separator$day';
}

String formatHmTime(DateTime? dateTime) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return '';
  final hour = localDateTime.hour.toString().padLeft(2, '0');
  final minute = localDateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatNotificationDateTime(DateTime? dateTime, [AppLocalizations? l10n]) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return l10n?.dateJustNow ?? '刚刚';

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfTarget = DateTime(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
  );
  final dayDiff = startOfToday.difference(startOfTarget).inDays;

  if (dayDiff == 0) {
    return formatHmTime(localDateTime);
  }
  if (dayDiff == 1) {
    return l10n?.dateYesterday ?? '昨天';
  }
  if (dayDiff > 1 && dayDiff < 7) {
    return l10n?.dateDaysAgo(dayDiff) ?? '$dayDiff天前';
  }
  return formatYmdDate(localDateTime, separator: '/');
}

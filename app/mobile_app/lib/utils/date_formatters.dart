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

String formatRelativeDateTime(DateTime? dateTime) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return '刚刚';

  final diff = DateTime.now().difference(localDateTime);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
  if (diff.inDays < 1) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return formatYmdDate(localDateTime);
}

String formatEditedRelativeDateTime(
  DateTime? createdAt,
  DateTime? updatedAt, {
  String editedLabel = '已编辑',
}) {
  final relative = formatRelativeDateTime(createdAt);
  if (!isEdited(createdAt, updatedAt)) {
    return relative;
  }

  return '$relative ($editedLabel)';
}

String formatYmdDate(DateTime? dateTime, {String separator = '-'}) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return '刚刚';
  final month = localDateTime.month.toString().padLeft(2, '0');
  final day = localDateTime.day.toString().padLeft(2, '0');
  return '${localDateTime.year}$separator$month$separator$day';
}

String formatHmTime(DateTime? dateTime) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return '刚刚';
  final hour = localDateTime.hour.toString().padLeft(2, '0');
  final minute = localDateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatNotificationDateTime(DateTime? dateTime) {
  final localDateTime = _toLocalDateTime(dateTime);
  if (localDateTime == null) return '刚刚';

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
    return '昨天';
  }
  if (dayDiff > 1 && dayDiff < 7) {
    return '$dayDiff天前';
  }
  return formatYmdDate(localDateTime, separator: '/');
}

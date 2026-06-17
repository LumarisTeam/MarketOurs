String formatRelativeDateTime(DateTime? dateTime) {
  if (dateTime == null) return '刚刚';

  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
  if (diff.inDays < 1) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return formatYmdDate(dateTime);
}

String formatYmdDate(DateTime? dateTime, {String separator = '-'}) {
  if (dateTime == null) return '刚刚';
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}$separator$month$separator$day';
}

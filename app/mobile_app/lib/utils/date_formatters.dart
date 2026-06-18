import '../l10n/app_localizations.dart';

String formatRelativeDateTime(DateTime? dateTime, AppLocalizations l10n) {
  if (dateTime == null) return l10n.dateJustNow;

  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return l10n.dateJustNow;
  if (diff.inHours < 1) return l10n.dateMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.dateHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.dateDaysAgo(diff.inDays);
  return formatYmdDate(dateTime);
}

String formatYmdDate(DateTime? dateTime, {String separator = '-'}) {
  if (dateTime == null) return '';
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}$separator$month$separator$day';
}

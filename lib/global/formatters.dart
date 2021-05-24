// Package imports:
import 'package:intl/intl.dart';

// @again_guy:matrix.org -> again_ereio
String formatSender(String sender) {
  return sender.replaceAll('@', '').split(':')[0];
}

String formatUserId(String displayName, {String homeserver = 'matrix.org'}) {
  return '@$displayName:$homeserver';
}

String formatLanguageCode(String? language) {
  switch ((language ?? 'english').toLowerCase()) {
    case 'english':
      return 'en';
    case 'russian':
      return 'ru';
    default:
      return 'en';
  }
}

// @again_guy:matrix.org -> ER
String formatSenderInitials(String sender) {
  final formattedSender = formatSender(sender).toUpperCase();
  return formattedSender.length < 2
      ? formattedSender
      : formattedSender.substring(0, 2);
}

String formatTimestampFull({
  int? lastUpdateMillis,
  bool showTime = false,
  String? timeFormat,
}) {
  if (lastUpdateMillis == null || lastUpdateMillis == 0) return '';

  final timestamp = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
  final hourFormat = timeFormat == '24hr' ? 'H:mm' : 'h:mm';

  return DateFormat(
    showTime ? 'MMM d $hourFormat a' : 'MMM d yyyy',
  ).format(timestamp);
}

// 1237597223894 -> 30m, now, etc
String formatTimestamp({
  int? lastUpdateMillis = 0,
  bool showTime = false,
  String timeFormat = '24hr',
}) {
  if (lastUpdateMillis == 0) return '';

  final timestamp = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis!);
  final sinceLastUpdate = DateTime.now().difference(timestamp);
  final hourFormat = timeFormat == '24hr' ? 'H:mm' : 'h:mm';

  if (sinceLastUpdate.inDays > 365) {
    return DateFormat(
      showTime ? 'MMM d $hourFormat a' : 'MMM d yyyy',
    ).format(timestamp);
  } else if (sinceLastUpdate.inDays > 6) {
    // Abbreviated month and day number - Jan 1
    return DateFormat(
      showTime ? 'MMM d $hourFormat a' : 'MMM d',
    ).format(timestamp);
  } else if (sinceLastUpdate.inDays > 0) {
    // Abbreviated weekday - Fri
    return DateFormat(showTime ? 'E $hourFormat a' : 'E').format(timestamp);
  } else if (sinceLastUpdate.inHours > 0) {
    // Abbreviated hours since - 1h
    return '${sinceLastUpdate.inHours}h';
  } else if (sinceLastUpdate.inMinutes > 0) {
    // Abbreviated minutes since - 1m
    return '${sinceLastUpdate.inMinutes}m';
  } else if (sinceLastUpdate.inSeconds > 1) {
    // Just say now if it's been within the minute
    return 'Now';
  } else {
    return 'Now';
  }
}

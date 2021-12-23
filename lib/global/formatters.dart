import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/settings/models.dart';

// @again_guy:matrix.org -> again_ereio
String formatSender(String sender) {
  return sender.replaceAll('@', '').split(':')[0];
}

String formatUserId(String displayName, {String homeserver = Values.homeserverDefault}) {
  return '@$displayName:$homeserver';
}

String findLocale(String language, {required BuildContext context}) {
  // TODO: remove length > 2 - accounting for pre 0.2 users
  if (language.isEmpty || language.length > 2) {
    return Localizations.localeOf(context).languageCode;
  }

  return language;
}

// @again_guy:matrix.org -> AG
// a -> A
String formatInitials(String? word) {
  final wordUppercase = (word ?? '').toUpperCase();
  return wordUppercase.length > 1 ? wordUppercase.substring(0, 2) : wordUppercase;
}

String formatInitialsLong(String? fullword) {
  //  -> ?
  if (fullword == null || fullword.isEmpty) {
    return '?';
  }

  final word = fullword.replaceAll('@', '');

  if (word.isEmpty) {
    return '?';
  }

  // example words -> EW
  if (word.length > 2 && word.contains(' ') && word.split(' ')[1].isNotEmpty) {
    final words = word.split(' ');
    final wordOne = words.elementAt(0);
    final wordTwo = words.elementAt(1);

    var initials = '';
    initials = wordOne.isEmpty ? initials : initials + wordOne.substring(0, 1);
    initials = wordTwo.isEmpty ? initials : initials + wordTwo.substring(0, 1);

    return initials.toUpperCase();
  }

  final initials = word.length > 1 ? word.substring(0, 2) : word.substring(0, 1);

  return initials.toUpperCase();
}

String formatTimestampFull({
  int lastUpdateMillis = 0,
  bool showTime = false,
  TimeFormat timeFormat = TimeFormat.hr12,
}) {
  if (lastUpdateMillis == 0) return '';

  final timestamp = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
  final hourFormat = timeFormat == TimeFormat.hr24 ? 'H:mm' : 'h:mm';

  return DateFormat(
    showTime ? 'MMM d $hourFormat a' : 'MMM d yyyy',
  ).format(timestamp);
}

// 1237597223894 -> 30m, now, etc
String formatTimestamp({
  int lastUpdateMillis = 0,
  bool showTime = false,
  TimeFormat timeFormat = TimeFormat.hr12,
}) {
  if (lastUpdateMillis == 0) return '';

  final timestamp = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
  final sinceLastUpdate = DateTime.now().difference(timestamp);
  final hourFormat = timeFormat == TimeFormat.hr24 ? 'H:mm' : 'h:mm';

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

formatUsernameHint({required String homeserver, String? username}) {
  final usernameFormatted = username != null && username.isNotEmpty ? username : 'username';
  final alias =
      homeserver.isNotEmpty ? '@$usernameFormatted:$homeserver' : '@$usernameFormatted:matrix.org';

  return alias.replaceFirst('@', '', 1);
}

import 'package:syphon/store/index.dart';

import './model.dart';

// Preauth
dynamic homeserver(AppState state) {
  return state.authStore.homeserver;
}

String trimmedUserId({String userId}) {
  return userId.replaceAll('@', '');
}

String userAlias({String username, String homeserver}) {
  return "@" + username + ":" + homeserver;
}

String formatShortname(String userId) {
  // If user has yet to save a username, format the userId to show the shortname
  return userId != null ? userId.split(':')[0].replaceAll('@', '') : '';
}

String displayShortname(User user) {
  // If user has yet to save a username, format the userId to show the shortname
  return user.userId != null
      ? user.userId.split(':')[0].replaceAll('@', '')
      : '';
}

String formatDisplayName(User user) {
  return user.displayName ?? displayShortname(user);
}

String displayInitials(User user) {
  final userId = user.userId ?? 'Unknown';
  final displayName = user.displayName ?? userId.replaceFirst('@', '');

  if (displayName.length > 0) {
    final initials = displayName.length > 1
        ? displayName.substring(0, 2)
        : userId.substring(0, 1);

    return initials.toUpperCase();
  }

  if (userId.length > 0) {
    final initials =
        userId.length > 1 ? userId.substring(0, 2) : userId.substring(0, 1);
    return initials.toUpperCase();
  }

  return 'NA';
}

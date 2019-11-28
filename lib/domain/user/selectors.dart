import 'package:Tether/domain/index.dart';

// Preauth
dynamic homeserver(AppState state) {
  return state.userStore.homeserver;
}

String username(AppState state) {
  return state.userStore.username;
}

String alias(AppState state) {
  return "@" + state.userStore.username + ":" + state.userStore.homeserver;
}

bool creating(AppState state) {
  return state.userStore.creating;
}

// Auth
String shortname(AppState state) {
  // If user has yet to save a username, format the userId to show the shortname
  final userId = state.userStore.user.userId;
  return userId != null ? userId.split(':')[0].replaceAll('@', '') : '';
}

String displayName(AppState state) {
  return state.userStore.user.displayName ?? shortname(state);
}

String displayInitials(AppState state) {
  final user = state.userStore.user;
  final displayName = user.displayName ?? user.userId.replaceFirst('@', '');
  final initials = displayName.contains(' ')
      ? displayName.split(' ')[0].substring(0, 1) +
          displayName.split(' ')[1].substring(0, 1)
      : displayName.substring(0, 2);
  return initials.toUpperCase();
}

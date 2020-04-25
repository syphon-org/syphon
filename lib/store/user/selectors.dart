import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/model.dart';

// Preauth
dynamic homeserver(AppState state) {
  return state.userStore.homeserver;
}

String username(AppState state) {
  return state.userStore.username.replaceAll('@', '');
}

String alias(AppState state) {
  return "@" + state.userStore.username + ":" + state.userStore.homeserver;
}

bool creating(AppState state) {
  return state.userStore.creating;
}

bool isLoginAttemptable(AppState state) {
  return state.userStore.isPasswordValid &&
      state.userStore.isUsernameValid &&
      !state.userStore.loading;
}

bool isAuthLoading(AppState state) {
  return state.userStore.loading;
}

// Auth
String displayShortname(User user) {
  // If user has yet to save a username, format the userId to show the shortname
  return user.userId != null
      ? user.userId.split(':')[0].replaceAll('@', '')
      : '';
}

String displayName(User user) {
  return user.displayName ?? displayShortname(user);
}

String displayInitials(User user) {
  if (user.userId == null) return 'NA';

  final displayName = user.displayName ?? user.userId.replaceFirst('@', '');
  final initials = displayName.contains(' ')
      ? displayName.split(' ')[0].substring(0, 1) +
          displayName.split(' ')[1].substring(0, 1)
      : displayName.substring(0, 2);
  return initials.toUpperCase();
}

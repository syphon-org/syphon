import 'package:Tether/domain/index.dart';

dynamic homeserver(AppState state) {
  return state.userStore.homeserver;
}

String alias(AppState state) {
  return "@" + state.userStore.username + ":" + state.userStore.homeserver;
}

String username(AppState state) {
  return state.userStore.username;
}

bool creating(AppState state) {
  return state.userStore.creating;
}

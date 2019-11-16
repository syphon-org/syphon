import 'package:Tether/domain/index.dart';

dynamic homeserver(AppState state) {
  return state.userStore.homeserver;
}

String alias(AppState state) {
  return "@" + state.userStore.username + ":" + state.userStore.homeserver;
}

bool creating(AppState state) {
  return state.userStore.creating;
}

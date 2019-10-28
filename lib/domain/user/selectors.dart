import 'package:Tether/domain/index.dart';

import './model.dart';

dynamic homeserver(AppState state) {
  return state.userStore.homeserver;
}

List<dynamic> homeservers(AppState state) {
  return state.userStore.homeservers;
}

List<dynamic> searchResults(AppState state) {
  return state.userStore.searchResults;
}

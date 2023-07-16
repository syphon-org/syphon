import 'package:syphon/domain/index.dart';

List<dynamic> homeservers(AppState state) {
  return state.searchStore.homeservers;
}

List<dynamic> searchResults(AppState state) {
  return state.searchStore.searchResults;
}

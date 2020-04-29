import 'package:Tether/store/index.dart';

List<dynamic> homeservers(AppState state) {
  return state.matrixStore.homeservers;
}

List<dynamic> searchResults(AppState state) {
  return state.matrixStore.searchResults;
}

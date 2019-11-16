import './model.dart';
import './actions.dart';

MatrixStore matrixReducer(
    [MatrixStore state = const MatrixStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetHomeservers:
      return state.copyWith(
          homeservers: action.homeservers, searchResults: action.homeservers);
    case UpdateHomeservers:
      return state.copyWith(
          homeservers: action.homeservers, searchResults: action.homeservers);
    case SetSearchResults:
      return state.copyWith(searchResults: action.homeservers);
    default:
      return state;
  }
}

import './model.dart';
import './actions.dart';

MatrixStore matrixReducer(
    [MatrixStore state = const MatrixStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return MatrixStore(
          loading: action.loading,
          homeservers: state.homeservers,
          searchResults: state.homeservers);
    case SetHomeservers:
      return MatrixStore(
          loading: state.loading,
          homeservers: action.homeservers,
          searchResults: action.homeservers);
    case UpdateHomeservers:
      return MatrixStore(
          loading: state.loading,
          homeservers: action.homeservers,
          searchResults: action.homeservers);
    case SetSearchResults:
      return MatrixStore(
          loading: state.loading,
          homeservers: state.homeservers,
          searchResults: action.searchResults);
    default:
      return state;
  }
}

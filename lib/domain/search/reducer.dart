import './actions.dart';
import './state.dart';

SearchStore searchReducer([SearchStore state = const SearchStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case SetLoading:
      return state.copyWith(
        loading: actionAny.loading,
      );
    case SetSearchText:
      return state.copyWith(
        searchText: actionAny.text,
      );
    case SetHomeservers:
      return state.copyWith(
        homeservers: actionAny.homeservers,
        searchResults: actionAny.homeservers,
      );
    case UpdateHomeservers:
      return state.copyWith(
        homeservers: actionAny.homeservers,
        searchResults: actionAny.homeservers,
      );
    case SetSearchResults:
      return state.copyWith(
        since: actionAny.since,
        searchText: actionAny.searchText,
        searchResults: actionAny.searchResults,
        totalResults: actionAny.totalResults,
      );
    case SearchMessages:
      return state.copyWith(
        loading: true,
      );
    case SearchMessageResults:
      final action = actionAny as SearchMessageResults;
      return state.copyWith(
        loading: false,
        searchMessages: action.results,
      );
    case ResetSearchResults:
      return state.copyWith(
        searchResults: [],
        searchMessages: const [],
      );
    default:
      return state;
  }
}

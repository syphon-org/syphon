import './actions.dart';
import './state.dart';

SearchStore searchReducer(
    [SearchStore state = const SearchStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(
        loading: action.loading,
      );
    case SetSearchText:
      return state.copyWith(
        searchText: action.text,
      );
    case SetHomeservers:
      return state.copyWith(
        homeservers: action.homeservers,
        searchResults: action.homeservers,
      );
    case UpdateHomeservers:
      return state.copyWith(
        homeservers: action.homeservers,
        searchResults: action.homeservers,
      );
    case SetSearchResults:
      return state.copyWith(
        since: action.since,
        searchText: action.searchText,
        searchResults: action.searchResults,
        totalResults: action.totalResults,
      );
    case SearchMessages:
      return state.copyWith(
        loading: true,
      );
    case SearchMessageResults:
      final _action = action as SearchMessageResults;
      return state.copyWith(
        loading: false,
        searchMessages: _action.results,
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

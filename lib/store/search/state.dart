// Package imports:
import 'package:equatable/equatable.dart';
import 'package:syphon/store/auth/homeserver/model.dart';

class SearchStore extends Equatable {
  final bool loading;
  final String? since;
  final bool? hasMore;
  final int totalResults;
  final String? searchText;
  final List<dynamic> searchResults;
  final List<dynamic> homeservers;

  const SearchStore({
    this.since,
    this.totalResults = 0,
    this.loading = false,
    this.homeservers = const [],
    this.searchResults = const [],
    this.searchText,
    this.hasMore,
  });

  @override
  List<Object?> get props => [
        since,
        loading,
        homeservers,
        totalResults,
        searchResults,
        searchText,
        hasMore,
      ];

  SearchStore copyWith({
    loading,
    since,
    totalResults,
    homeservers,
    searchResults,
    searchText,
    hasMore,
  }) =>
      SearchStore(
        since: since,
        loading: loading ?? this.loading,
        totalResults: totalResults ?? this.totalResults,
        homeservers: homeservers ?? this.homeservers,
        searchResults: searchResults ?? this.searchResults,
        searchText: searchText ?? this.searchText,
        hasMore: hasMore ?? this.hasMore,
      );
}

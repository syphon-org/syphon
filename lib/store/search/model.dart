import 'package:Tether/store/rooms/room/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:equatable/equatable.dart';

// TODO: rename to searchStore
@jsonSerializable
class MatrixStore extends Equatable {
  final bool loading;
  final String since;
  final int totalResults;
  final String searchText;
  final bool hasMore;
  final List<dynamic> searchResults;
  final List<dynamic> homeservers;

  const MatrixStore({
    this.loading = false,
    this.since,
    this.totalResults = 0,
    this.homeservers = const [],
    this.searchResults = const [],
    this.searchText,
    this.hasMore,
  });

  MatrixStore copyWith({
    loading,
    since,
    totalResults,
    homeservers,
    searchResults,
    searchText,
    hasMore,
  }) =>
      MatrixStore(
        since: since,
        loading: loading ?? this.loading,
        totalResults: totalResults ?? this.totalResults,
        homeservers: homeservers ?? this.homeservers,
        searchResults: searchResults ?? this.searchResults,
        searchText: searchText ?? this.searchText,
        hasMore: hasMore ?? this.hasMore,
      );

  @override
  List<Object> get props => [
        since,
        loading,
        homeservers,
        totalResults,
        searchResults,
        searchText,
        hasMore,
      ];
}

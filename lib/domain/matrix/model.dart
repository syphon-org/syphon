import 'package:Tether/domain/rooms/room/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MatrixStore {
  // TODO: rename to search store
  final bool loading;
  final String since;
  final int totalResults;
  final String searchText;
  final List<Room> searchResults;
  final List<dynamic> homeservers;

  const MatrixStore({
    this.loading = false,
    this.since,
    this.totalResults = 0,
    this.homeservers = const [],
    this.searchResults = const [],
    this.searchText,
  });

  MatrixStore copyWith({
    loading,
    since,
    totalResults,
    homeservers,
    searchResults,
    searchText,
  }) =>
      MatrixStore(
        since: since,
        loading: loading ?? this.loading,
        totalResults: totalResults ?? this.totalResults,
        homeservers: homeservers ?? this.homeservers,
        searchResults: searchResults ?? this.searchResults,
        searchText: searchText ?? this.searchText,
      );

  @override
  int get hashCode =>
      since.hashCode ^
      loading.hashCode ^
      homeservers.hashCode ^
      totalResults.hashCode ^
      searchResults.hashCode ^
      searchText.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatrixStore &&
          runtimeType == other.runtimeType &&
          since == other.since &&
          loading == other.loading &&
          totalResults == other.totalResults &&
          homeservers == other.homeservers &&
          searchResults == other.searchResults &&
          searchText == other.searchText;
}

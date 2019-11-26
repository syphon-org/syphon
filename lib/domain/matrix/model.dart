class MatrixStore {
  final bool loading;
  final List<dynamic> homeservers;
  final List<dynamic> searchResults;

  const MatrixStore(
      {this.loading = false,
      this.homeservers = const [],
      this.searchResults = const []});

  MatrixStore copyWith({
    loading,
    homeservers,
    searchResults,
  }) {
    return MatrixStore(
      loading: loading ?? this.loading,
      homeservers: homeservers ?? this.homeservers,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  int get hashCode =>
      searchResults.hashCode ^ homeservers.hashCode ^ loading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatrixStore &&
          runtimeType == other.runtimeType &&
          loading == other.loading &&
          homeservers == other.homeservers &&
          searchResults == other.searchResults;

  @override
  String toString() {
    return '{loading: $loading, homeservers: $homeservers, searchResults: $searchResults}';
  }
}

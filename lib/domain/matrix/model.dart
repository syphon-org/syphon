class MatrixStore {
  final bool loading;
  final List<dynamic> homeservers;
  final List<dynamic> searchResults;

  const MatrixStore(
      {this.loading = false,
      this.homeservers = const [],
      this.searchResults = const []});

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
          searchResults == other.searchResults &&
          loading == other.loading;

  @override
  String toString() {
    return 'MatrixStore {homeservers: $homeservers, searchResults: $searchResults loading: $loading,}';
  }
}

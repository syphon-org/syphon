// @again_ereio:matrix.org -> ER
List<int> fibonacci(int n) {
  if (n == 0) {
    return [0];
  }
  if (n == 1) {
    return [0, 1];
  }
  final series = fibonacci(n - 1);
  series.add(series[series.length - 1] + series[series.length - 2]);
  return series;
}

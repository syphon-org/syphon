// Dart imports:
import 'dart:convert';

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

void printJson(Map jsonMap) {
  JsonEncoder encoder = new JsonEncoder.withIndent('  ');
  String prettyEvent = encoder.convert(jsonMap);
  print(prettyEvent);
}

/**
 * Clock functions in code
 * 
 * final stopwatch = Stopwatch()..start();
 * print('[fetchRooms] TIMESTAMP ${stopwatch.elapsed}');
 * stopwatch.stop();
 */

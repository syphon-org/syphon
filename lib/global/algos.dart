import 'package:syphon/global/print.dart';

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

// time functions by wrapping them here - needs testing
Future timeWrapper(
  Future<dynamic> Function() function, {
  String name = 'Anonymous',
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();

  final dynamic result = await function();

  final stoptime = stopwatch.elapsed;

  printDebug('[$name TIMER] ${function.runtimeType} $stoptime');

  return result;
}

String enumToString(dynamic enumItem) {
  return enumItem.toString().split('.')[1];
}

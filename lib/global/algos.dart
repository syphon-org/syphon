// Dart imports:
import 'dart:convert';

import 'package:flutter/material.dart';
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

void printJson(Map jsonMap) {
  JsonEncoder encoder = new JsonEncoder.withIndent('  ');
  String prettyEvent = encoder.convert(jsonMap);
  debugPrint(prettyEvent, wrapWidth: 2048);
}

// time functions by wrapping them here - needs testing
Future<void> timeWrapper(
  Future<dynamic> Function() function, {
  String name,
}) async {
  Stopwatch stopwatch = new Stopwatch()..start();

  dynamic result = await function();

  final stoptime = stopwatch.elapsed;

  printDebug('[$name TIMER] ${function.runtimeType} $stoptime');

  return result;
}

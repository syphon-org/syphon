import 'dart:math';

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

String getRandomString(int length) {
  const ch = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
  final r = Random();
  return String.fromCharCodes(
      Iterable.generate(length, (_) => ch.codeUnitAt(r.nextInt(ch.length))));
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

Future onFocusSafe(
    {FocusNode? focusNode, required Future<void> Function() onFunction}) async {
  if (focusNode == null) return Future.value();

  if (!focusNode.hasFocus) {
    // Unfocus all focus nodes
    focusNode.unfocus();

    // Disable text field's focus node request
    focusNode.canRequestFocus = false;
  }

  // Do your stuff
  await onFunction();

  if (!focusNode.hasFocus) {
    //Enable the text field's focus node request after some delay
    Future.delayed(Duration(milliseconds: 100), () {
      focusNode.canRequestFocus = true;
    });
  }
}

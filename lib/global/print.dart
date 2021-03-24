import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

typedef PrintInfo = void Function(String message, {String tag});
typedef PrintDebug = void Function(String message, {String tag});
typedef PrintWarning = void Function(String message, {String tag});
typedef PrintError = void Function(String message, {String tag});

class SimpleLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.levelColors[event.level];
    final emoji = PrettyPrinter.levelEmojis[event.level];
    print(color('$emoji - ${event.message}'));
  }
}

final logger = Logger();

void _printInfo(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.i(body);
}

void _printDebug(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.d(body);
}

void _printWarning(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.w(body);
}

void _printError(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.e(body);
}

PrintInfo printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintWarning printWarning = _printWarning;
PrintError printError = _printError;

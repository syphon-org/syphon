import 'package:flutter/material.dart';

typedef PrintDebug = void Function(String message, {String title});
typedef PrintError = void Function(String message, {String title});

void _printInfo(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  print('\u001b[32m$body\u001b[0m');
}

void _printWarning(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  print('\u001b[34m$body\u001b[0m');
}

void _printError(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  debugPrint('\u001b[31m$body\u001b[0m');
}

void _printDebug(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  debugPrint(body);
}

PrintDebug printInfo = _printInfo;
PrintDebug printDebug = _printDebug;

PrintError printError = _printError;
PrintError printWarning = _printWarning;

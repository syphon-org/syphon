import 'package:flutter/material.dart';

typedef PrintDebug = void Function(String message, {String title});
typedef PrintError = void Function(String message, {String? title});

void _printInfo(String content, {String? title}) {
  final body = title != null ? '[$title] $content' : content;
  print(body);
}

void _printWarning(String content, {String? title}) {
  final body = title != null ? '[$title] $content' : content;
  print(body);
}

void _printError(String content, {String? title}) {
  final body = title != null ? '[$title] $content' : content;
  print(body);
}

void _printDebug(String content, {String? title}) {
  final body = title != null ? '[$title] $content' : content;
  debugPrint(body);
}

PrintDebug printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintError printError = _printError;
PrintError printWarning = _printWarning;

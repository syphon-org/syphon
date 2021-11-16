import 'dart:convert';

import 'package:flutter/material.dart';

typedef PrintJson = void Function(Map? jsonMap);
typedef PrintDebug = void Function(String message, {String title});
typedef PrintError = void Function(String message, {String? title});

void _printInfo(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  print(output);
}

void _printWarning(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  print(output);
}

void _printError(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  print(output);
}

void _printDebug(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  debugPrint(output);
}

void _printJson(Map? jsonMap) {
  final JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final String prettyEvent = encoder.convert(jsonMap);
  debugPrint(prettyEvent, wrapWidth: 2048);
}

PrintJson printJson = _printJson;
PrintDebug printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintError printError = _printError;
PrintError printWarning = _printWarning;

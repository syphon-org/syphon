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

// TODO: convert with better tab completion
class Print {
  static info(String content, {String? title}) => _printInfo(content, title: title);
  static warn(String content, {String? title}) => _printWarning(content, title: title);
  static error(String content, {String? title}) => _printError(content, title: title);
  static debug(String content, {String? title}) => _printDebug(content, title: title);
  static json(Map? json) => _printJson(json);
}

final log = Print();

PrintJson printJson = _printJson;
PrintDebug printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintError printError = _printError;
PrintError printWarning = _printWarning;

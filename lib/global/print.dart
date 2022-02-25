import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syphon/global/values.dart';

typedef PrintJson = void Function(Map? jsonMap);
typedef PrintDebug = void Function(String message, {String title});
typedef PrintError = void Function(String message, {String? title});

void _printInfo(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  if (DEBUG_MODE) {
    print(output);
  }
}

void _printWarning(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  if (DEBUG_MODE) {
    print(output);
  }
}

void _printError(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  if (DEBUG_MODE) {
    print(output);
  }
}

void _printDebug(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  if (DEBUG_MODE) {
    debugPrint(output);
  }
}

void _printJson(Map? jsonMap) {
  final JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final String prettyEvent = encoder.convert(jsonMap);
  if (DEBUG_MODE) {
    debugPrint(prettyEvent, wrapWidth: 2048);
  }
}

PrintJson printJson = _printJson;
PrintDebug printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintError printError = _printError;
PrintError printWarning = _printWarning;

// NOTE: start using this for better tab completion
// ignore: camel_case_types
class log {
  static info(String content, {String? title}) => _printInfo(content, title: title);
  static warn(String content, {String? title}) => _printWarning(content, title: title);
  static error(String content, {String? title}) => _printError(content, title: title);
  static debug(String content, {String? title}) => _printDebug(content, title: title);
  static json(Map? json) => _printJson(json);
}

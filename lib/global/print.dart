import 'package:ansicolor/ansicolor.dart';
import 'package:flutter/material.dart';

typedef PrintDebug = void Function(String message, {String title});
typedef PrintError = void Function(String message, {String title});

void _printInfo(String content, {String title}) {
  final pen = AnsiPen()..white(bold: true);
  final body = title != null ? '[$title] $content' : content;
  print(pen(body));
}

void _printWarning(String content, {String title}) {
  final pen = AnsiPen()..yellow(bold: true);
  final body = title != null ? '[$title] $content' : content;
  print(pen(body));
}

void _printError(String content, {String title}) {
  final pen = AnsiPen()..red(bold: true);
  final body = title != null ? '[$title] $content' : content;
  print(pen(body));
}

void _printDebug(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  debugPrint(body);
}

PrintDebug printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintError printError = _printError;
PrintError printWarning = _printWarning;

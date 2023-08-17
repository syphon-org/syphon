// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syphon/global/values.dart';

typedef VarArgsCallback = void Function(List<dynamic> args);

class VarArgsFunction {
  final VarArgsCallback callback;

  VarArgsFunction(this.callback);

  void call() => callback([]);

  @override
  dynamic noSuchMethod(Invocation inv) {
    return callback(
      inv.positionalArguments,
    );
  }
}

typedef PrintJson = void Function(Map? jsonMap);
typedef PrintDebug = void Function(String message, {String title});
typedef PrintError = void Function(String message, {String? title});

void _printThreaded(String content, {String? title}) {
  if (DEBUG_MODE) {
    final output = title != null ? '[$title] $content' : content;
    print('[bg   ] $output');
  }
}

void _printInfo(String content, {String? title}) {
  if (DEBUG_MODE) {
    final output = title != null ? '[$title] $content' : content;
    print('[info ] $output');
  }
}

void _printWarning(String content, {String? title}) {
  if (DEBUG_MODE) {
    final output = title != null ? '[$title] $content' : content;
    print('[warn ] $output');
  }
}

void _printError(String content, {String? title}) {
  if (DEBUG_MODE) {
    final output = title != null ? '[$title] $content' : content;
    print('[ERROR] $output');
  }
}

void _printRelease(String content, {String? title}) {
  final output = title != null ? '[$title] $content' : content;
  print('[prod ] $output');
}

void _printJson(Map? jsonMap) {
  if (DEBUG_MODE) {
    final JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String prettyEvent = encoder.convert(jsonMap);
    debugPrint(prettyEvent, wrapWidth: 2048);
  }
}

// NOTE: start using this for better tab completion
// ignore: camel_case_types
class console {
  static info(String content, {String? title}) => false; //_printInfo(content, title: title);
  static warn(String content, {String? title}) => _printWarning(content, title: title);
  static error(String content, {String? title}) => _printError(content, title: title);
  static threaded(String content, {String? title}) => _printThreaded(content, title: title);
  static release(String content, {String? title}) => _printRelease(content, title: title);
  static json(Map? json) => _printJson(json);
  static jsonDebug(Map? json) => _printJson(json);

  static final dynamic debug = VarArgsFunction((args) {
    if (DEBUG_MODE) {
      if (args[0] != false) {
        final output = args.join(' ');
        print('[DEBUG] $output');
      }
    }
  });
}

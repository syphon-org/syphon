import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

bool isSystemDarkMode() {
  return SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
}

import 'dart:ui';

bool isSystemDarkMode() {
  return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
}

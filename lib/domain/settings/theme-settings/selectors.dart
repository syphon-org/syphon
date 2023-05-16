import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:syphon/global/algos.dart';

import 'package:syphon/global/colors.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/domain/settings/models.dart';
import 'model.dart';

bool isSystemDarkMode() {
  return SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
}

ThemeType themeTypeFromSystem() {
  if (isSystemDarkMode()) {
    return ThemeType.Dark;
  }

  return ThemeType.Light;
}

ThemeType resolveThemeOverride(ThemeType themeType) {
  var themeTypeOverride = themeType;
  if (themeTypeOverride == ThemeType.System) {
    themeTypeOverride = themeTypeFromSystem();
  }

  return themeTypeOverride;
}

String selectMainFabType(ThemeSettings themeSettings) {
  return enumToString(themeSettings.mainFabType);
}

String selectMainFabLocation(ThemeSettings themeSettings) {
  return enumToString(themeSettings.mainFabLocation);
}

String selectMainFabLabels(ThemeSettings themeSettings) {
  return enumToString(themeSettings.mainFabLabel);
}

String selectThemeTypeString(ThemeType themeType) {
  return enumToString(themeType);
}

Color selectPrimaryColor(ThemeSettings themeSettings) {
  return Color(themeSettings.primaryColor);
}

Color selectAccentColor(ThemeSettings themeSettings) {
  return Color(themeSettings.accentColor);
}

Color computeContrastColorText(Color? color, {double ratio = 0.5}) {
  return (color ?? Colors.white).computeLuminance() < ratio ? Colors.white : Colors.black;
}

SystemUiOverlayStyle computeSystemUIColor(BuildContext context, {double ratio = 0.5}) {
  return Theme.of(context).scaffoldBackgroundColor.computeLuminance() < ratio
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;
}

int selectRowHighlightColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return AppColors.greyLightest;
    case ThemeType.Night:
      return AppColors.greyDarkest;
    default:
      return AppColors.greyDark;
  }
}

int selectSystemUiColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return AppColors.whiteDefault;
    case ThemeType.Night:
      return AppColors.blackFull;
    default:
      return AppColors.blackDefault;
  }
}

Brightness selectSystemUiIconColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Brightness.dark;
    default:
      return Brightness.light;
  }
}

Color selectIconBackground(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Color(AppColors.greyDefault);
    case ThemeType.Night:
      return Color(AppColors.greyDefault);
    default:
      return Color(AppColors.greyDark);
  }
}

Color selectAvatarBackground(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Color(AppColors.greyLightest);
    case ThemeType.Night:
      return Color(AppColors.greyDefault);
    default:
      return Color(AppColors.greyDark);
  }
}

Brightness selectThemeBrightness(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Brightness.light;
    default:
      return Brightness.dark;
  }
}

Color selectIconColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Colors.grey[500]!;
    default:
      return Colors.white;
  }
}

Color? selectModalColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Night:
      return Colors.grey[900];
    default:
      return null;
  }
}

int? selectScaffoldBackgroundColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return AppColors.whiteDefault;
    case ThemeType.Darker:
      return AppColors.blackDefault;
    case ThemeType.Night:
      return AppColors.blackFull;
    default:
      return null;
  }
}

Color selectInputTextColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Color(AppColors.blackDefault);
    default:
      return Colors.white;
  }
}

Color selectCursorColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Colors.blueGrey;
    default:
      return Colors.white;
  }
}

Color selectInputBackgroundColor(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Light:
      return Color(AppColors.greyEnabled);
    case ThemeType.Dark:
      return Colors.grey[800]!;
    default:
      return Colors.grey[850]!;
  }
}

double? selectAppBarElevation(ThemeType themeTypeNew) {
  final themeType = resolveThemeOverride(themeTypeNew);

  switch (themeType) {
    case ThemeType.Darker:
      return 0.0;
    case ThemeType.Night:
      return 0.0;
    default:
      return null;
  }
}

String selectReadReceiptsString(ReadReceiptTypes readReceipts) {
  switch (readReceipts) {
    case ReadReceiptTypes.On:
      return Strings.labelOn;
    case ReadReceiptTypes.Off:
      return Strings.labelOff;
    case ReadReceiptTypes.Private:
      return Strings.labelPrivate;
    default: //I've not been coded for this one yet
      return readReceipts.name;
  }
}

String selectFontNameString(FontName fontName) {
  return enumToString(fontName);
}

double? selectFontLetterSpacing(FontName fontName) {
  switch (fontName) {
    case FontName.Rubik:
      return 0.5;
    default:
      return null;
  }
}

FontWeight selectFontTitleWeight(FontName fontName) {
  switch (fontName) {
    case FontName.Rubik:
      return FontWeight.w100;
    default:
      return FontWeight.w400;
  }
}

FontWeight selectFontBodyWeight(FontName fontName) {
  switch (fontName) {
    default:
      return FontWeight.w400;
  }
}

String selectFontSizeString(FontSize fontSize) {
  return enumToString(fontSize);
}

double selectFontSubtitleSize(FontSize fontSize) {
  switch (fontSize) {
    case FontSize.Small:
      return 12;
    case FontSize.Large:
      return 16;
    default:
      return 14;
  }
}

double selectFontSubtitleSizeLarge(FontSize fontSize) {
  switch (fontSize) {
    case FontSize.Small:
      return 14;
    case FontSize.Large:
      return 18;
    default:
      return 16;
  }
}

double selectFontBodySize(FontSize fontSize) {
  switch (fontSize) {
    case FontSize.Small:
      return 16;
    case FontSize.Large:
      return 20;
    default:
      return 18;
  }
}

double selectFontBodySizeLarge(FontSize fontSize) {
  switch (fontSize) {
    case FontSize.Small:
      return 18;
    case FontSize.Large:
      return 22;
    default:
      return 20;
  }
}

String selectMessageSizeString(MessageSize messageSize) {
  return enumToString(messageSize);
}

double selectMessageSizeDouble(MessageSize messageSize) {
  switch (messageSize) {
    case MessageSize.Small:
      return 10;
    case MessageSize.Large:
      return 14;
    default:
      return 12;
  }
}

String selectAvatarShapeString(AvatarShape avatarShape) {
  return enumToString(avatarShape);
}

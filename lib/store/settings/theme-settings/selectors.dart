import 'package:flutter/material.dart';
import 'package:syphon/global/algos.dart';

import 'package:syphon/global/colours.dart';
import 'model.dart';

String selectThemeTypeString(ThemeType themeType) {
  return enumToString(themeType);
}

Color selectPrimaryColor(ThemeSettings themeSettings) {
  return Color(themeSettings.primaryColor);
}

Color selectAccentColor(ThemeSettings themeSettings) {
  return Color(themeSettings.accentColor);
}

int selectSystemUiColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Colours.whiteDefault;
    case ThemeType.Night:
      return Colours.blackFull;
    default:
      return Colours.blackDefault;
  }
}

Brightness selectSystemUiIconColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Brightness.dark;
    default:
      return Brightness.light;
  }
}

Color selectBackgroundBrightness(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Color(Colours.greyLightest);
    case ThemeType.Night:
      return Color(Colours.greyDefault);
    default:
      return Color(Colours.greyDark);
  }
}

Brightness selectThemeBrightness(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Brightness.light;
    default:
      return Brightness.dark;
  }
}

Color selectIconColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Colors.grey[500]!;
    default:
      return Colors.white;
  }
}

Color? selectModalColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Night:
      return Colors.grey[900];
    default:
      return null;
  }
}

int? selectScaffoldBackgroundColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Colours.whiteDefault;
    case ThemeType.Darker:
      return Colours.blackDefault;
    case ThemeType.Night:
      return Colours.blackFull;
    default:
      return null;
  }
}

Color selectInputTextColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Color(Colours.blackDefault);
    default:
      return Colors.white;
  }
}

Color selectCursorColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Colors.blueGrey;
    default:
      return Colors.white;
  }
}

Color selectInputBackgroundColor(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Light:
      return Color(Colours.greyEnabled);
    case ThemeType.Dark:
      return Colors.grey[800]!;
    default:
      return Colors.grey[850]!;
  }
}

double? selectAppBarElevation(ThemeType themeType) {
  switch (themeType) {
    case ThemeType.Darker:
      return 0.0;
    case ThemeType.Night:
      return 0.0;
    default:
      return null;
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

String selectAvatarShapeString(AvatarShape avatarShape) {
  return enumToString(avatarShape);
}

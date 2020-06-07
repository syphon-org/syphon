// decoration: BoxDecoration( // DEBUG ONLY
//   color: Colors.red,
// ),

import 'package:flutter/material.dart';

class Dimensions {
  // Generic
  static const double widgetHeightMax = 1024;

  // Media
  static const double mediaSizeMin = 208;
  static const double mediaSizeMax = 320;

  static const double thumbnailSizeMin = 48;
  static const double thumbnailSizeMax = 48;

  // Avatars
  static const double avatarSizeMessage = 28;
  static const double avatarSize = 56; // was 52
  static const double avatarSizeMax = 350; // Change to HeroSize
  static const double avatarHeroSize = 120;

  // Buttons
  static const double buttonWidthMin = 256;
  static const double buttonWidthMax = 296;
  static const double buttonAppBarSize = 26;

  // Messages
  static const double bubbleHeightMin = 54;
  static const double bubbleWidthMin = 122;

  // Icons
  static const double iconSize = 26;
  static const double iconSizeLite = 24;
  static const double indicatorSize = 16;
  static const double miniLockSize = 12;

  // Progress
  static const double progressIndicatorSize = 26;
  static const double progressIndicatorSizeLite = 12;

  // Inputs
  static const double inputSizeMin = 200;
  static const double inputSizeMax = 296;

  static const double inputHeight = 52;
  static const double inputWidthMin = inputSizeMin;
  static const double inputWidthMax = inputSizeMax; // 43 * 8

  // Lists
  static const heroPadding = EdgeInsets.symmetric(
    vertical: 24,
    horizontal: 24,
  );

  static const listPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  static listPaddingDynamic({width = 500}) {
    return EdgeInsets.only(
      left: width * 0.04,
      right: width * 0.04,
      top: 6,
      bottom: 14,
    );
  }

  static listTitlePaddingDynamic({width = 500}) {
    return EdgeInsets.only(
      left: width * 0.04,
      right: width * 0.04,
      top: 6,
      bottom: 14,
    );
  }

  // Content
  static const contentPadding = EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 8,
  );

  static contentPaddingDynamic({width = 500}) {
    return EdgeInsets.symmetric(
      horizontal: width * 0.04,
      vertical: 4,
    );
  }

  // Page Viewer
  static const double pageViewerWidthMin = 326;
  static const double pageViewerHeightMin = 326;
  static const double pageViewerHeightMax = widgetHeightMax / 2;

  // Progress Indicator
  static const double defaultStrokeWidth = 2;
  static const double defaultStrokeWidthLite = 1.5;

  // * Device Specific *
  static const buttonlessHeightiOS = 736;
}

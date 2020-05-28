// decoration: BoxDecoration( // DEBUG ONLY
//   color: Colors.red,
// ),

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
  static const double buttonWidthMax = 384;
  static const double buttonAppBarSize = 26;

  // Messages
  static const double bubbleHeightMin = 54;
  static const double bubbleWidthMin = 122;

  // Icons
  static const double iconSize = 26;
  static const double iconSizeLite = 24;
  static const double indicatorSize = 16;

  // Progress
  static const double progressIndicatorSize = 26;
  static const double progressIndicatorSizeLite = 12;

  // Inputs
  static const double inputSizeMin = 200;
  static const double inputSizeMax = 320;

  static const double inputHeight = 52;
  static const double inputWidthMin = inputSizeMin;
  static const double inputWidthMax = inputSizeMax; // 43 * 8

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

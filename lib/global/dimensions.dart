// decoration: BoxDecoration( // DEBUG ONLY
//   color: Colors.red,
// ),

class Dimensions {
  // Generic
  static const double widgetHeightMax = 1024;

  // Media
  static const double mediaSizeMin = 208;
  static const double mediaSizeMax = 320;

  // Buttons
  static const double buttonWidthMin = 256;
  static const double buttonWidthMax = 384;

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

  // * Device Specific *
  static const buttonlessHeightiOS = 736;
}

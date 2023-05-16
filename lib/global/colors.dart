import 'package:flutter/material.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/domain/user/selectors.dart';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';

  double delta(Color color2) {
    // ignore: unnecessary_this
    final hex1 = this.toHex(leadingHashSign: false);
    final hex2 = color2.toHex(leadingHashSign: false);

    // get red/green/blue int values of hex1
    final r1 = int.parse(hex1.substring(0, 2), radix: 16);
    final g1 = int.parse(hex1.substring(2, 4), radix: 16);
    final b1 = int.parse(hex1.substring(4, 6), radix: 16);
    // get red/green/blue int values of hex2
    final r2 = int.parse(hex2.substring(0, 2), radix: 16);
    final g2 = int.parse(hex2.substring(2, 4), radix: 16);
    final b2 = int.parse(hex2.substring(4, 6), radix: 16);
    // calculate differences between reds, greens and blues
    var r = 255 - (r1 - r2).abs().toDouble();
    var g = 255 - (g1 - g2).abs().toDouble();
    var b = 255 - (b1 - b2).abs().toDouble();
    // limit differences between 0 and 1
    r /= 255;
    g /= 255;
    b /= 255;

    // 0 means opposite colors, 1 means same colors
    return (r + g + b) / 3;
  }
}

class AppColors {
  static const cyanSyphon = 0xff34C7B5;
  static const cyanSyphonAlpha = 0xAA34C7B5;

  static const blueBubbly = 0xff4476CC;
  static const blueDark = 0xFF00246E;

  static const greyEnabled = 0xffFAFAFA;
  static const greyDisabled = 0xffD8D8D8;

  static const greyLightest = 0xFFEEEEEE; // Colors.grey[200]
  static const greyLight = 0xFFE0E0E0; // Colors.grey[300]
  static const greyDefault = 0xFF9E9E9E; // Colors.grey[500]
  static const greyDark = 0xFF616161; // Colors.grey[700]
  static const greyDarkest = 0xFF303030; // Colors.grey[850]

  static const blackFull = 0xff000000;
  static const blackDefault = 0xff121212;
  static const whiteDefault = 0xffFEFEFE;

  // Material colors at shades of 700
  static const chatRed = 0xFFC62828;
  static const chatOrange = 0xFFF57C00;
  static const chatPurple = 0xFF7B1FA2;
  static const chatGreen = 0xFF388E3C;
  static const chatMagenta = 0xFFC2185B;
  static const chatTeal = 0xFF00796B;
  static const chatBlue = 0xFF1976D2;

  static Color hashedColor(String? string) {
    final hashable = string ?? Values.defaultUserId;
    final int hash = hashable.codeUnits.reduce((value, element) => value + element);
    return AppColors.chatColors[hash % AppColors.chatColors.length];
  }

  static Color hashedColorUser(User? user) {
    return hashedColor(safeUserId(user));
  }

  static const chatColors = [
    Color(AppColors.chatRed),
    Color(AppColors.chatOrange),
    Color(AppColors.chatPurple),
    Color(AppColors.chatTeal),
    Color(AppColors.chatMagenta),
    Color(AppColors.chatGreen),
    Color(AppColors.chatBlue),
  ];
}

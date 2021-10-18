import 'package:flutter/material.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';

/// British localization because
/// google monopolized the namespaces
class Colours {
  static const cyanSyphon = 0xff34C7B5;
  static const cyanSyphonAlpha = 0xAA34C7B5;

  static const blueBubbly = 0xff4476CC;

  static const greyEnabled = 0xffFAFAFA;
  static const greyDisabled = 0xffD8D8D8;

  static const greyDefault = 0xFF9E9E9E; // Colors.grey[500]
  static const greyLight = 0xFFE0E0E0; // Colors.grey[300]
  static const greyLightest = 0xFFEEEEEE; // Colors.grey[200]
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
    final int hash =
        hashable.codeUnits.reduce((value, element) => value + element);
    return Colours.chatColors[hash % Colours.chatColors.length];
  }

  static Color hashedColorUser(User? user) {
    return hashedColor(safeUserId(user));
  }

  static const chatColors = [
    Color(Colours.chatRed),
    Color(Colours.chatOrange),
    Color(Colours.chatPurple),
    Color(Colours.chatTeal),
    Color(Colours.chatMagenta),
    Color(Colours.chatGreen),
    Color(Colours.chatBlue),
  ];
}

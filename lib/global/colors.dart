import 'package:flutter/material.dart';

const TETHERED_CYAN = 0xff34C7B5;
const TETHERED_CYAN_ALPHA = 0xAA34C7B5;
const BESIDES_BLUE = 0xff4476CC;
const BASICALLY_BLACK = 0xff121212;
const ACTUALLY_BLACK = 0xff000000;
const ENABLED_GREY = 0xffFAFAFA;
const DISABLED_GREY = 0xffD8D8D8;
const GREY_DARK = 0xff4D5767;
const BACKGROUND = 0xffFEFEFE;

const PRIMARY_COLOR = const Color(TETHERED_CYAN);
const PRIMARY_COLOR_ALPHA = const Color(TETHERED_CYAN);
const BASICALLY_BLACK_COLOR = const Color(BASICALLY_BLACK);
const ENABLED_GREY_COLOR = const Color(ENABLED_GREY);
const DISABLED_GREY_COLOR = const Color(DISABLED_GREY);
const BACKGROUND_COLOR = const Color(BACKGROUND);
const GREY_DARK_COLOR = const Color(GREY_DARK);

// Material colors at shades of 700
const DEFAULT_RED = 0xFFC62828;
const DEFAULT_ORANGE = 0xFFF57C00;
const DEFAULT_PURPLE = 0xFF7B1FA2;
const DEFAULT_GREEN = 0xFF388E3C;
const DEFAULT_MAGENTA = 0xFFC2185B;
const DEFAULT_TEAL = 0xFF00796B;
const DEFAULT_BLUE = 0xFF1976D2;

const CHAT_COLORS = [
  Color(DEFAULT_RED),
  Color(DEFAULT_ORANGE),
  Color(DEFAULT_PURPLE),
  Color(DEFAULT_TEAL),
  Color(DEFAULT_MAGENTA),
  Color(DEFAULT_GREEN),
  Color(DEFAULT_BLUE),
];

Color hashedColor(String hashable) {
  int hash = hashable.codeUnits.reduce((value, element) => value + element);
  return CHAT_COLORS[hash % CHAT_COLORS.length];
}

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/colours.dart';

part 'model.g.dart';

@JsonSerializable()
class Theme extends Equatable {
  final int primaryColor;
  final int accentColor;
  final int appBarColor;
  final int brightness;
  final ThemeType themeType;
  final String fontName;
  final String fontSize;
  final String messageSize;
  final String avatarShape;

  const Theme({
    this.primaryColor = Colours.cyanSyphon,
    this.accentColor = Colours.cyanSyphon,
    this.appBarColor = Colours.cyanSyphon,
    this.brightness = 0,
    this.themeType = ThemeType.LIGHT,
    this.fontName = 'Rubik',
    this.fontSize = 'Default',
    this.messageSize = 'Default',
    this.avatarShape = 'Circle',
  });

  @override
  List<Object?> get props => [
    primaryColor,
    accentColor,
    appBarColor,
    brightness,
    themeType,
    fontName,
    fontSize,
    messageSize,
    avatarShape,
  ];

  Theme copyWith({
    int? primaryColor,
    int? accentColor,
    int? appBarColor,
    int? brightness,
    ThemeType? themeType,
    String? fontName,
    String? fontSize,
    String? messageSize,
    String? avatarShape,
  }) =>
      Theme(
        primaryColor: primaryColor ?? this.primaryColor,
        accentColor: accentColor ?? this.accentColor,
        appBarColor: appBarColor ?? this.appBarColor,
        brightness: brightness ?? this.brightness,
        themeType: themeType ?? this.themeType,
        fontName: fontName ?? this.fontName,
        fontSize: fontSize ?? this.fontSize,
        messageSize: messageSize ?? this.messageSize,
        avatarShape: avatarShape ?? this.avatarShape,
      );

  Map<String, dynamic> toJson() => _$ThemeToJson(this);

  factory Theme.fromJson(Map<String, dynamic> json) => _$ThemeFromJson(json);
}

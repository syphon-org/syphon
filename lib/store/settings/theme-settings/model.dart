// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/colours.dart';

part 'model.g.dart';

// Theme-related types
enum ThemeType {
  Light,
  Dark,
  Darker,
  Night,
}
enum FontName {
  Rubik,
  Roboto,
  Poppins,
  Inter,
}
enum MessageSize {
  Small,
  Default,
  Large,
}
enum FontSize {
  Small,
  Default,
  Large,
}
enum AvatarShape {
  Circle,
  Square,
}

@JsonSerializable()
class AppTheme extends Equatable {
  final int primaryColor;
  final int accentColor;
  final int appBarColor;
  final int brightness;
  final ThemeType themeType;
  final FontName fontName;
  final FontSize fontSize;
  final MessageSize messageSize;
  final AvatarShape avatarShape;

  const AppTheme({
    this.primaryColor = Colours.cyanSyphon,
    this.accentColor = Colours.cyanSyphon,
    this.appBarColor = Colours.cyanSyphon,
    this.brightness = 0,
    this.themeType = ThemeType.Light,
    this.fontName = FontName.Rubik,
    this.fontSize = FontSize.Default,
    this.messageSize = MessageSize.Default,
    this.avatarShape = AvatarShape.Circle,
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

  AppTheme copyWith({
    int? primaryColor,
    int? accentColor,
    int? appBarColor,
    int? brightness,
    ThemeType? themeType,
    FontName? fontName,
    FontSize? fontSize,
    MessageSize? messageSize,
    AvatarShape? avatarShape,
  }) =>
      AppTheme(
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

  Map<String, dynamic> toJson() => _$AppThemeToJson(this);

  factory AppTheme.fromJson(Map<String, dynamic> json) => _$AppThemeFromJson(json);
}

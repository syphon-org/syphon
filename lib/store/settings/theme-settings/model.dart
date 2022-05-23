import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:syphon/global/colors.dart';

part 'model.g.dart';

// Theme-related types
enum ThemeType {
  Light,
  Dark,
  Darker,
  Night,
  System,
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

enum MainFabType {
  Ring,
  Bar,
}

enum MainFabLocation {
  Right,
  Left,
}

enum MainFabLabel {
  On,
  Off,
  // Short,
}

@JsonSerializable()
class ThemeSettings extends Equatable {
  final int primaryColor;
  final int accentColor;
  final int appBarColor;
  final int brightness;
  final ThemeType themeType;
  final FontName fontName;
  final FontSize fontSize;
  final MessageSize messageSize;
  final AvatarShape avatarShape;
  final MainFabType mainFabType;
  final MainFabLabel mainFabLabel;
  final MainFabLocation mainFabLocation;

  const ThemeSettings({
    this.primaryColor = AppColors.cyanSyphon,
    this.accentColor = AppColors.cyanSyphon,
    this.appBarColor = AppColors.cyanSyphon,
    this.brightness = 0,
    this.themeType = ThemeType.Light,
    this.fontName = FontName.Rubik,
    this.fontSize = FontSize.Default,
    this.messageSize = MessageSize.Default,
    this.avatarShape = AvatarShape.Circle,
    this.mainFabType = MainFabType.Ring,
    this.mainFabLabel = MainFabLabel.Off,
    this.mainFabLocation = MainFabLocation.Right,
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
        mainFabType,
        mainFabLabel,
        mainFabLocation,
      ];

  ThemeSettings copyWith({
    int? primaryColor,
    int? accentColor,
    int? appBarColor,
    int? brightness,
    ThemeType? themeType,
    FontName? fontName,
    FontSize? fontSize,
    MessageSize? messageSize,
    AvatarShape? avatarShape,
    MainFabType? mainFabType,
    MainFabLabel? mainFabLabel,
    MainFabLocation? mainFabLocation,
  }) =>
      ThemeSettings(
        primaryColor: primaryColor ?? this.primaryColor,
        accentColor: accentColor ?? this.accentColor,
        appBarColor: appBarColor ?? this.appBarColor,
        brightness: brightness ?? this.brightness,
        themeType: themeType ?? this.themeType,
        fontName: fontName ?? this.fontName,
        fontSize: fontSize ?? this.fontSize,
        messageSize: messageSize ?? this.messageSize,
        avatarShape: avatarShape ?? this.avatarShape,
        mainFabType: mainFabType ?? this.mainFabType,
        mainFabLabel: mainFabLabel ?? this.mainFabLabel,
        mainFabLocation: mainFabLocation ?? this.mainFabLocation,
      );

  Map<String, dynamic> toJson() => _$ThemeSettingsToJson(this);

  factory ThemeSettings.fromJson(Map<String, dynamic> json) => _$ThemeSettingsFromJson(json);
}

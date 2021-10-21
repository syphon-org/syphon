import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/store/settings/chat-settings/actions.dart';

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

enum MainFabType {
  Ring,
  Bar,
  // Circle,
}

enum MainFabLocation {
  Right,
  Left,
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
  final MainFabLocation mainFabLocation;
  final ReadReceiptTypes readReceipts;

  const ThemeSettings({
    this.primaryColor = Colours.cyanSyphon,
    this.accentColor = Colours.cyanSyphon,
    this.appBarColor = Colours.cyanSyphon,
    this.brightness = 0,
    this.themeType = ThemeType.Light,
    this.fontName = FontName.Rubik,
    this.fontSize = FontSize.Default,
    this.messageSize = MessageSize.Default,
    this.avatarShape = AvatarShape.Circle,
    this.mainFabType = MainFabType.Ring,
    this.mainFabLocation = MainFabLocation.Right,
    this.readReceipts = ReadReceiptTypes.Off,
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
        mainFabLocation,
        readReceipts,
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
    MainFabLocation? mainFabLocation,
    ReadReceiptTypes? readReceipts,
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
        mainFabLocation: mainFabLocation ?? this.mainFabLocation,
        readReceipts: readReceipts ?? this.readReceipts,
      );

  Map<String, dynamic> toJson() => _$ThemeSettingsToJson(this);

  factory ThemeSettings.fromJson(Map<String, dynamic> json) =>
      _$ThemeSettingsFromJson(json);
}

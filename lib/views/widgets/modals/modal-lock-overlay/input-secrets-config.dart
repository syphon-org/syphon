import 'package:flutter/material.dart';

class InputSecretsConfig {
  const InputSecretsConfig({
    this.spacing,
    this.spacingRatio = 0.05,
    this.padding = const EdgeInsets.only(top: 24, bottom: 40),
    this.secretConfig = const InputSecretConfig(),
  });

  /// Absolute space between secret widgets.
  /// If specified together with spacingRatio, this will take precedence.
  final double? spacing;

  /// Space ratio between secret widgets.
  ///
  /// Default `0.05`
  final double spacingRatio;

  /// padding of Secrets Widget.
  ///
  /// Default [EdgeInsets.only(top: 20, bottom: 50)]
  final EdgeInsetsGeometry padding;

  final InputSecretConfig secretConfig;
}

/// Configuration of [Secret]
class InputSecretConfig {
  const InputSecretConfig({
    this.width = 16,
    this.height = 20,
    this.borderSize = 1.0,
    this.borderColor = Colors.white,
    this.enabledColor = Colors.white,
    this.disabledColor = Colors.transparent,
    this.build,
  });

  final double width;
  final double height;
  final double borderSize;
  final Color borderColor;
  final Color enabledColor;
  final Color disabledColor;

  /// `build` override function
  final Widget Function(
    BuildContext context, {
    required bool enabled,
    required InputSecretConfig config,
  })? build;

  InputSecretConfig copyWith({
    double? width,
    double? height,
    double? borderSize,
    Color? borderColor,
    Color? enabledColor,
    Color? disabledColor,
  }) {
    return InputSecretConfig(
      width: width ?? this.width,
      height: height ?? this.height,
      borderSize: borderSize ?? this.borderSize,
      borderColor: borderColor ?? this.borderColor,
      enabledColor: enabledColor ?? this.enabledColor,
      disabledColor: disabledColor ?? this.disabledColor,
    );
  }
}

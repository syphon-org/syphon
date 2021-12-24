import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/input-secrets-config.dart';
import 'package:vector_math/vector_math_64.dart';

class InputSecret extends StatelessWidget {
  const InputSecret({
    Key? key,
    this.enabled = false,
    this.config = const InputSecretConfig(),
  }) : super(key: key);

  final bool enabled;

  final InputSecretConfig config;

  @override
  Widget build(BuildContext context) {
    if (config.build != null) {
      // Custom build.
      return config.build!(
        context,
        config: config,
        enabled: enabled,
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? config.enabledColor : config.disabledColor,
        border: Border.all(
          width: config.borderSize,
          color: config.borderColor,
        ),
      ),
      width: config.width,
      height: config.height,
    );
  }
}

class SineCurve extends Curve {
  const SineCurve({this.count = 3});
  final double count;

  // 2. override transformInternal() method
  @override
  double transformInternal(double t) {
    return sin(count * 2 * pi * t);
  }
}

class InputSecrets extends StatefulWidget {
  const InputSecrets({
    Key? key,
    this.config = const InputSecretsConfig(),
    required this.inputStream,
    required this.verifyStream,
    required this.length,
  }) : super(key: key);

  final InputSecretsConfig config;
  final Stream<String> inputStream;
  final Stream<bool> verifyStream;
  final int length;

  @override
  _InputSecretsState createState() => _InputSecretsState();
}

class _InputSecretsState extends State<InputSecrets> with SingleTickerProviderStateMixin {
  bool? enabled;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            _animationController.reverse();
          }
        },
      );

    Tween<double>(
      begin: 50.0,
      end: 120.0,
    ).animate(_animationController);

    widget.verifyStream.listen((valid) {
      if (!valid) {
        // shake animation when invalid
        _animationController.forward();
      } else {
        enabled = false;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Vector3 _shake() {
    final double progress = _animationController.value;
    final double offset = sin(progress * pi * 10.0);
    return Vector3(offset * 10, 0.0, 0.0);
  }

  double _computeSpacing(BuildContext context) {
    if (widget.config.spacing != null) {
      return widget.config.spacing!;
    }

    return MediaQuery.of(context).size.width * widget.config.spacingRatio;
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.translation(_shake()),
      child: StreamBuilder<String>(
        stream: widget.inputStream,
        builder: (context, snapshot) {
          return Container(
            padding: widget.config.padding,
            child: Wrap(
              spacing: _computeSpacing(context),
              children: widget.length < 1
                  ? [Container(height: widget.config.secretConfig.height + 4.0)]
                  : List.generate(
                      widget.length,
                      (index) {
                        if (!snapshot.hasData) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: InputSecret(
                              config: widget.config.secretConfig,
                              enabled: false,
                            ),
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: InputSecret(
                            config: widget.config.secretConfig,
                            enabled: enabled ?? index < snapshot.data!.length,
                          ),
                        );
                      },
                      growable: false,
                    ),
            ),
          );
        },
      ),
    );
  }
}

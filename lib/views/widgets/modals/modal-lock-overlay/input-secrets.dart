import 'package:flutter/material.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/input-secrets-config.dart';

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
  late Animation<Offset> _animation;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    widget.verifyStream.listen((valid) {
      if (!valid) {
        // shake animation when invalid
        _animationController.forward();
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _animation = _animationController
        .drive(CurveTween(curve: Curves.elasticIn))
        .drive(Tween<Offset>(begin: Offset.zero, end: const Offset(0.05, 0)))
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _computeSpacing(BuildContext context) {
    if (widget.config.spacing != null) {
      return widget.config.spacing!;
    }

    return MediaQuery.of(context).size.width * widget.config.spacingRatio;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: StreamBuilder<String>(
        stream: widget.inputStream,
        builder: (context, snapshot) {
          return Container(
            padding: widget.config.padding,
            child: Wrap(
              spacing: _computeSpacing(context),
              children: widget.length < 1
                  ? [Container(height: widget.config.secretConfig.height)]
                  : List.generate(
                      widget.length,
                      (index) {
                        if (!snapshot.hasData) {
                          return InputSecret(
                            config: widget.config.secretConfig,
                            enabled: false,
                          );
                        }

                        return InputSecret(
                          config: widget.config.secretConfig,
                          enabled: index < snapshot.data!.length,
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

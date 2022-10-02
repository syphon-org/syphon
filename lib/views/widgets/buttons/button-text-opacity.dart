import 'package:flutter/material.dart';
import 'package:syphon/global/colors.dart';

import 'package:syphon/global/dimensions.dart';

class ButtonTextOpacity extends StatefulWidget {
  const ButtonTextOpacity({
    Key? key,
    this.text,
    this.textWidget,
    this.loading = false,
    this.disabled = false,
    this.color,
    this.onPressed,
  }) : super(key: key);

  final bool loading;
  final bool disabled;
  final String? text;
  final Widget? textWidget;
  final Color? color;
  final Function? onPressed;

  @override
  ButtonTextState createState() => ButtonTextState();
}

class ButtonTextState extends State<ButtonTextOpacity> {
  double opacity = 1;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: widget.disabled ? 0.4 : opacity,
        child: GestureDetector(
          onTap: widget.disabled ? null : () => widget.onPressed?.call(),
          onTapDown: (details) => setState(() {
            opacity = 0.4;
          }),
          onTapCancel: () => setState(() {
            opacity = 1;
          }),
          onTapUp: (details) => setState(() {
            opacity = 1;
          }),
          child: widget.loading
              ? Container(
                  constraints: BoxConstraints(
                    maxHeight: 24,
                    maxWidth: 24,
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: Dimensions.strokeWidthDefault,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey,
                    ),
                  ),
                )
              : (widget.textWidget ??
                  Text(
                    widget.text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 0.8,
                      color: () {
                        if (widget.disabled) {
                          return Color(AppColors.greyLight);
                        }
                        if (widget.color != null) {
                          return widget.color;
                        }
                        return Theme.of(context).textTheme.button!.color;
                      }(),
                    ),
                  )),
        ),
      );
}

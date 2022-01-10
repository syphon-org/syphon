import 'package:flutter/material.dart';
import 'package:syphon/global/colours.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/loader/loading-indicator.dart';

class ButtonSolid extends StatelessWidget {
  const ButtonSolid({
    Key? key,
    this.text,
    this.textWidget,
    this.loading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.onPressed,
  }) : super(key: key);

  final bool loading;
  final bool disabled;
  final double? width;
  final double? height;
  final String? text;
  final Widget? textWidget;
  final Function? onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: width ?? Dimensions.contentWidth(context),
        height: height ?? Dimensions.inputHeight,
        constraints: BoxConstraints(
          minWidth: Dimensions.buttonWidthMin,
          maxWidth: Dimensions.buttonWidthMax,
        ),
        child: TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) => states.contains(MaterialState.disabled)
                  ? Color(Colours.greyLight)
                  : Theme.of(context).primaryColor,
            ),
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) => states.contains(MaterialState.disabled)
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
            ),
            shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
              (Set<MaterialState> states) => RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.0),
              ),
            ),
          ),
          onPressed: disabled ? null : onPressed as void Function()?,
          child: loading
              ? LoadingIndicator()
              : (textWidget != null
                  ? textWidget!
                  : Text(
                      text!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w100,
                        letterSpacing: 0.8,
                        color: disabled ? Color(Colours.greyLight) : Colors.white,
                      ),
                    )),
        ),
      );
}

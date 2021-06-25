import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syphon/global/colours.dart';

import 'package:syphon/global/dimensions.dart';

class ButtonText extends StatelessWidget {
  const ButtonText({
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
  Widget build(BuildContext context) => TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) =>
                states.contains(MaterialState.disabled)
                    ? Color(Colours.greyDisabled)
                    : null,
          ),
        ),
        onPressed: disabled ? null : onPressed as void Function()?,
        child: loading
            ? Container(
                constraints: BoxConstraints(
                  maxHeight: 24,
                  maxWidth: 24,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: Dimensions.defaultStrokeWidth,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey,
                  ),
                ),
              )
            : (textWidget != null
                ? textWidget!
                : Text(
                    text!,
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyText1?.fontSize,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 0.8,
                      color: () {
                        if (disabled) {
                          return Color(Colours.greyDisabled);
                        }
                        if (color != null) {
                          return color;
                        }
                        return Theme.of(context).textTheme.bodyText1?.color;
                      }(),
                    ),
                  )),
      );
}

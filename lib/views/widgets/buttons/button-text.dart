import 'package:flutter/material.dart';
import 'package:syphon/global/colors.dart';

import 'package:syphon/global/dimensions.dart';

class ButtonText extends StatelessWidget {
  const ButtonText({
    super.key,
    this.text,
    this.color,
    this.size,
    this.textWidget,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
  });

  final bool loading;
  final bool disabled;
  final double? size;
  final Color? color;
  final String? text;
  final Widget? textWidget;
  final Function? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) =>
                states.contains(MaterialState.disabled) ? const Color(AppColors.greyDisabled) : null,
          ),
        ),
        onPressed: disabled ? null : onPressed as void Function()?,
        child: loading
            ? Container(
                constraints: const BoxConstraints(
                  maxHeight: 24,
                  maxWidth: 24,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: Dimensions.strokeWidthDefault,
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
                      fontSize: size ?? Theme.of(context).textTheme.bodyLarge?.fontSize,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 0.8,
                      color: () {
                        if (disabled) {
                          return const Color(AppColors.greyDisabled);
                        }
                        if (color != null) {
                          return color;
                        }
                        return Theme.of(context).primaryColor;
                      }(),
                    ),
                  )),
      );
}

// Flutter imports:
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';

/**
 * Secured Text Field Input
 * 
 * Remove all auto completions by default
 * Other functionality that could indicate
 * text content
 */
class TextFieldSecure extends StatelessWidget {
  TextFieldSecure({
    Key key,
    this.label,
    this.hint,
    this.suffix,
    this.focusNode,
    this.controller,
    this.maxLines = 1,
    this.valid = true,
    this.disabled = false,
    this.obscureText = false,
    this.disableSpacing = false,
    this.textAlign = TextAlign.left,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
  }) : super(key: key);

  final bool valid;
  final bool disabled;
  final bool obscureText;
  final bool disableSpacing;
  final int maxLines;
  final Widget suffix; // include actions
  final String hint;
  final String label;
  final TextAlign textAlign;

  final FocusNode focusNode;
  final TextEditingController controller;

  final Function onChanged;
  final Function onSubmitted;
  final Function onEditingComplete;

  @override
  Widget build(BuildContext context) => Container(
        child: TextField(
          enabled: !disabled,
          maxLines: maxLines,
          focusNode: focusNode,
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          autocorrect: false,
          enableSuggestions: false,
          selectionHeightStyle: BoxHeightStyle.max,
          inputFormatters: !disableSpacing
              ? [
                  BlacklistingTextInputFormatter(RegExp(r"\t")),
                ]
              : [
                  BlacklistingTextInputFormatter(RegExp(r"\s")),
                  BlacklistingTextInputFormatter(RegExp(r"\t")),
                  BlacklistingTextInputFormatter(RegExp(r"\n")),
                ],
          smartQuotesType: SmartQuotesType.disabled,
          smartDashesType: SmartDashesType.disabled,
          textAlign: textAlign,
          obscureText: obscureText,
          cursorColor: Theme.of(context).primaryColor,
          keyboardAppearance: Theme.of(context).brightness,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: suffix,
            contentPadding: Dimensions.inputPadding,
            border: OutlineInputBorder(
              borderSide: !valid
                  ? BorderSide()
                  : BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
              borderRadius: BorderRadius.circular(
                Dimensions.inputBorderRadius,
              ),
            ),
          ),
        ),
        height: Dimensions.inputHeight,
        constraints: BoxConstraints(
          minWidth: Dimensions.inputWidthMin,
          maxWidth: Dimensions.inputWidthMax,
        ),
      );
}

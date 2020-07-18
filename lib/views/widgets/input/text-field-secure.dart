import 'package:flutter/services.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    this.suffix,
    this.focusNode,
    this.controller,
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
  final Widget suffix; // include actions
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
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: !disableSpacing
              ? null
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

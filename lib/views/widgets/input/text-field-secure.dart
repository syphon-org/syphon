import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:syphon/global/dimensions.dart';

const DEFAULT_BORDER_WIDTH = 1.2;

///
/// Secured Text Field Input
///
/// Remove all auto completions by default
/// Other functionality that could indicate
/// text content
///
class TextFieldSecure extends StatelessWidget {
  const TextFieldSecure({
    Key? key,
    this.label,
    this.hint,
    this.suffix,
    this.focusNode,
    this.controller,
    this.maxLines = 1,
    this.valid = true,
    this.dirty = false,
    this.disabled = false,
    this.readOnly = false,
    this.obscureText = false,
    this.disableSpacing = false,
    this.autocorrect = false,
    this.enabledSuggestions = false,
    this.enableInteractiveSelection = true,
    this.textAlign = TextAlign.left,
    this.formatters = const [],
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.textInputAction,
    this.autofillHints,
    this.mouseCursor = MaterialStateMouseCursor.textable,
  }) : super(key: key);

  final bool valid;
  final bool dirty;
  final bool disabled;
  final bool readOnly;
  final bool obscureText;
  final bool disableSpacing;
  final bool autocorrect;
  final bool enabledSuggestions;
  final bool enableInteractiveSelection;

  final int maxLines;
  final Widget? suffix; // include actions
  final String? hint;
  final String? label;
  final TextAlign textAlign;

  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final List<TextInputFormatter> formatters;

  final Function? onChanged;
  final Function? onSubmitted;
  final Function? onEditingComplete;
  final Function? onTap;
  final Iterable<String>? autofillHints;
  final MaterialStateMouseCursor? mouseCursor;

  buildBorderColorFocused(BuildContext context) {
    if (disabled) {
      return BorderSide(
        color: Theme.of(context).disabledColor,
      );
    }

    if (!valid && dirty) {
      return BorderSide(
        color: Theme.of(context).errorColor,
        width: DEFAULT_BORDER_WIDTH,
      );
    }

    return BorderSide(
      color: Theme.of(context).primaryColor,
      width: DEFAULT_BORDER_WIDTH,
    );
  }

  buildBorderColor(BuildContext context) {
    if (disabled) {
      return BorderSide(
        color: Theme.of(context).disabledColor,
      );
    }

    if (!valid && dirty) {
      return BorderSide(
        color: Theme.of(context).errorColor.withOpacity(0.75),
        width: DEFAULT_BORDER_WIDTH,
      );
    }

    return BorderSide(
      color: Theme.of(context).dividerColor,
      width: DEFAULT_BORDER_WIDTH,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        height: Dimensions.inputHeight,
        constraints: BoxConstraints(
          minWidth: Dimensions.inputWidthMin,
          maxWidth: Dimensions.inputWidthMax,
        ),
        child: TextField(
          enabled: !disabled,
          readOnly: readOnly,
          maxLines: maxLines,
          focusNode: focusNode,
          controller: controller,
          onChanged: onChanged as void Function(String)?,
          onSubmitted: onSubmitted as void Function(String)?,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete as void Function()?,
          onTap: onTap as void Function()?,
          autocorrect: autocorrect,
          enableSuggestions: enabledSuggestions,
          autofillHints: disabled ? null : autofillHints,
          selectionHeightStyle: BoxHeightStyle.max,
          enableInteractiveSelection: enableInteractiveSelection,
          inputFormatters: !disableSpacing
              ? [
                  FilteringTextInputFormatter.deny(RegExp(r'\t')),
                  ...formatters,
                ]
              : [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  FilteringTextInputFormatter.deny(RegExp(r'\t')),
                  FilteringTextInputFormatter.deny(RegExp(r'\n')),
                  ...formatters,
                ],
          smartQuotesType: SmartQuotesType.disabled,
          smartDashesType: SmartDashesType.disabled,
          textAlign: textAlign,
          obscureText: obscureText,
          cursorColor: Theme.of(context).primaryColor,
          keyboardAppearance: Theme.of(context).brightness,
          mouseCursor: mouseCursor,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: suffix,
            contentPadding: Dimensions.inputPadding,
            focusedBorder: OutlineInputBorder(
              borderSide: buildBorderColorFocused(context),
              borderRadius: BorderRadius.circular(
                Dimensions.inputBorderRadius,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: buildBorderColor(context),
              borderRadius: BorderRadius.circular(
                Dimensions.inputBorderRadius,
              ),
            ),
          ),
        ),
      );
}

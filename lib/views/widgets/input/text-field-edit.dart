import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';

///
/// Secured Text Field Input
///
/// Remove all auto completions by default
/// Other functionality that could indicate
/// text content
///
class TextFieldInline extends StatefulWidget {
  const TextFieldInline({
    Key? key,
    this.body,
    this.onEdit,
  }) : super(key: key);

  final String? body;

  final Function? onEdit;
  @override
  State<TextFieldInline> createState() => _TextFieldInlineState();
}

class _TextFieldInlineState extends State<TextFieldInline> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.body?.trim());
  }

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
        child: TextField(
          maxLines: null,
          autocorrect: false,
          enableSuggestions: false,
          controller: controller,
          textInputAction: TextInputAction.send,
          onEditingComplete: () {
            if (widget.onEdit != null) {
              widget.onEdit!(controller.value.text.toString());
            }
          },
          decoration: InputDecoration(
            filled: true,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
            contentPadding: Dimensions.inputContentPadding.copyWith(right: 36),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
        ),
      );
}

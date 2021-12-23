import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

///
/// Secured Text Field Input
///
/// Remove all auto completions by default
/// Other functionality that could indicate
/// text content
///
class TextFieldInline extends StatefulWidget {
  final String? body;
  final bool autofocus;
  final TextEditingController? controller;

  final Function? onEdit;

  const TextFieldInline({
    Key? key,
    this.body,
    this.onEdit,
    this.autofocus = false,
    this.controller,
  }) : super(key: key);

  @override
  State<TextFieldInline> createState() => _TextFieldInlineState();
}

class _TextFieldInlineState extends State<TextFieldInline> with Lifecycle<TextFieldInline> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController(text: widget.body?.trim());
  }

  @override
  void onMounted() {
    _controller.text = widget.body?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
        child: TextField(
          maxLines: null,
          autocorrect: false,
          enableSuggestions: false,
          autofocus: widget.autofocus,
          controller: _controller,
          textInputAction: TextInputAction.send,
          onEditingComplete: () {
            if (widget.onEdit != null) {
              widget.onEdit!(_controller.value.text.toString());
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

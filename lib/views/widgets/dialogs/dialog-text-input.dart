import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

import 'package:syphon/views/widgets/loader/loading-indicator.dart';

class DialogTextInput extends StatefulWidget {
  const DialogTextInput({
    Key? key,
    this.title = '',
    this.content = '',
    this.label = '',
    this.loading = false,
    this.valid = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.editingController,
    this.onConfirm,
    this.onChange,
    this.onCancel,
  }) : super(key: key);

  final String title;
  final String content;
  final String label;
  final bool loading;
  final bool valid;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextEditingController? editingController;

  final Function? onChange;
  final Function? onConfirm;
  final Function? onCancel;

  @override
  _DialogTextInputState createState() => _DialogTextInputState();
}

class _DialogTextInputState extends State<DialogTextInput> {
  final editingControllerDefault = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double defaultWidgetScaling = width * 0.725;

    final editingController =
        widget.editingController ?? editingControllerDefault;

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: EdgeInsets.only(
        left: 24,
        right: 16,
        top: 16,
        bottom: 16,
      ),
      contentPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      title: Text(widget.title),
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: defaultWidgetScaling,
              margin: const EdgeInsets.only(
                top: 16,
                bottom: 16,
                left: 8,
              ),
              child: Text(
                widget.content,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            Container(
              width: defaultWidgetScaling,
              height: Dimensions.inputHeight,
              margin: const EdgeInsets.only(
                bottom: 32,
              ),
              constraints: BoxConstraints(
                minWidth: Dimensions.inputWidthMin,
                maxWidth: Dimensions.inputWidthMax,
              ),
              child: TextField(
                controller: editingController,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(
                    top: 32,
                    left: 20,
                    bottom: 32,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  labelText: widget.label,
                ),
                onChanged: (value) {
                  if (widget.onChange != null) {
                    widget.onChange!(value);
                  }
                },
                onSubmitted: (value) {
                  if (widget.onConfirm != null) {
                    widget.onConfirm!(value);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: widget.loading
                  ? null
                  : () {
                      if (widget.onCancel != null) {
                        widget.onCancel!();
                      }
                      Navigator.of(context).pop();
                    },
              child: Text(Strings.buttonCancel),
            ),
            TextButton(
              onPressed: !editingController.value.text.isNotEmpty
                  ? null
                  : () {
                      if (widget.onConfirm != null &&
                          editingController.value.text.isNotEmpty) {
                        widget.onConfirm!(editingController.value.text);
                      }
                      Navigator.of(context).pop();
                    },
              child: !widget.loading
                  ? Text(Strings.buttonSave)
                  : LoadingIndicator(size: 16),
            ),
          ],
        )
      ],
    );
  }
}

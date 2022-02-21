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
    this.initialValue = '',
    this.loading = false,
    this.valid = false,
    this.obscureText = false,
    this.confirmText = '',
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
  final String initialValue;
  final String confirmText;

  final bool loading;
  final bool valid;
  final bool obscureText;
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
  final inputFieldNode = FocusNode();

  bool isEmpty = true;
  bool visibility = false;
  bool localLoading = false;
  TextEditingController editingControllerDefault = TextEditingController();
  @override
  void initState() {
    super.initState();
    editingControllerDefault.text = widget.initialValue;

    editingControllerDefault.addListener(() {
      setState(() {
        isEmpty = editingControllerDefault.text.isEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double defaultWidgetScaling = width * 0.725;

    final editingController = widget.editingController ?? editingControllerDefault;

    final loading = localLoading || widget.loading;

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: EdgeInsets.only(
        left: 24,
        right: 16,
        top: 16,
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
                top: 12,
                bottom: 20,
              ),
              constraints: BoxConstraints(
                minWidth: Dimensions.inputWidthMin,
                maxWidth: Dimensions.inputWidthMax,
              ),
              child: TextField(
                enabled: !loading,
                focusNode: inputFieldNode,
                controller: editingController,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                obscureText: widget.obscureText && (!visibility || loading),
                decoration: InputDecoration(
                  suffix: widget.obscureText
                      ? GestureDetector(
                          onTap: () => setState(() {
                            visibility = !visibility;
                          }),
                          child: Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Icon(
                              visibility ? Icons.visibility : Icons.visibility_off,
                              color: visibility ? Theme.of(context).primaryColor : null,
                            ),
                          ),
                        )
                      : null,
                  contentPadding: EdgeInsets.only(
                    left: 20,
                    right: !widget.obscureText ? 0 : 20,
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
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      if (widget.onCancel != null) {
                        widget.onCancel!();
                      }
                    },
              child: Text(Strings.buttonCancel),
            ),
            TextButton(
              onPressed: loading || isEmpty
                  ? null
                  : () async {
                      if (widget.onConfirm != null && !isEmpty) {
                        inputFieldNode.unfocus();
                        setState(() {
                          localLoading = true;
                          visibility = false;
                        });
                        await widget.onConfirm!(editingController.text);
                        setState(() {
                          localLoading = false;
                        });
                      }
                    },
              child: !loading
                  ? Text(widget.confirmText.isEmpty ? Strings.buttonSave : widget.confirmText)
                  : LoadingIndicator(size: 16),
            ),
          ],
        )
      ],
    );
  }
}

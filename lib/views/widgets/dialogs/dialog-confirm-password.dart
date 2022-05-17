// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/widgets/loader/loading-indicator.dart';

class DialogConfirmPassword extends StatefulWidget {
  const DialogConfirmPassword({
    Key? key,
    required this.title, // i18n Strings isn't a constant. You gotta pass it in
    required this.content, // i18n Strings isn't a constant. You gotta pass it in
    this.valid = true,
    this.loading = false,
    this.checkValid,
    this.checkLoading,
    this.onCancel,
    this.onConfirm,
    this.onChangePassword,
  }) : super(key: key);

  // TODO: figure out why these don't work, but in dialog-confirm it does
  // TODO: was previously stateless and that didn't help, worth trying again though
  final bool valid;
  final bool loading;

  // TODO: remove after above works
  final Function? checkValid;
  final Function? checkLoading;

  final String title;
  final String content;

  final Function? onCancel;
  final Function? onConfirm;
  final Function? onChangePassword;

  @override
  State<DialogConfirmPassword> createState() => _DialogConfirmPasswordState();
}

class _DialogConfirmPasswordState extends State<DialogConfirmPassword> {
  var _valid = false;
  var _loading = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double defaultWidgetScaling = width * 0.725;

    final loading =
        widget.loading || (widget.checkLoading != null ? widget.checkLoading!() : false);
    final valid = widget.valid || (widget.checkValid != null ? widget.checkValid!() : false);

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
                onChanged: (password) {
                  if (widget.onChangePassword == null) return;
                  widget.onChangePassword!(password);

                  setState(() {
                    _valid = password.isNotEmpty;
                  });
                },
                obscureText: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(
                    left: 20,
                    top: 32,
                    bottom: 32,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  labelText: Strings.labelPassword,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: !loading ? () => widget.onCancel?.call() : null,
              child: Text(
                Strings.buttonCancel,
              ),
            ),
            TextButton(
              onPressed: !valid
                  ? null
                  : () {
                      if (widget.onConfirm != null) {
                        widget.onConfirm!();

                        setState(() {
                          _loading = true;
                        });
                      }
                    },
              child: !loading
                  ? Text(Strings.buttonConfirmFormal,
                      style: TextStyle(
                        color:
                            valid ? Theme.of(context).primaryColor : Color(AppColors.greyDisabled),
                      ))
                  : LoadingIndicator(),
            ),
          ],
        )
      ],
    );
  }
}

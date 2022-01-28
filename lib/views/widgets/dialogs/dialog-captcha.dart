import 'package:flutter/material.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/captcha.dart';

class DialogCaptcha extends StatefulWidget {
  const DialogCaptcha({
    Key? key,
    this.hostname,
    this.publicKey,
    this.onCancel,
    this.onComplete,
  }) : super(key: key);

  final String? hostname;
  final String? publicKey;

  final Function? onCancel;
  final Function? onComplete;

  @override
  State<DialogCaptcha> createState() => _DialogCaptchaState();
}

class _DialogCaptchaState extends State<DialogCaptcha> {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

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
        left: 8,
        right: 8,
        bottom: 16,
      ),
      title: Text(Strings.titleDialogCaptcha),
      children: <Widget>[
        Container(
          width: width,
          child: SingleChildScrollView(
            child: Container(
              width: width,
              height: height * 0.5,
              constraints: BoxConstraints(
                minWidth: Dimensions.inputWidthMin,
                maxWidth: Dimensions.inputWidthMax,
              ),
              child: Captcha(
                baseUrl: widget.hostname,
                publicKey: widget.publicKey,
                onVerified: (token) => widget.onComplete!(token),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            ButtonText(
              text: Strings.buttonCancel,
              onPressed: () {
                if (widget.onCancel != null) {
                  widget.onCancel!();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      ],
    );
  }
}

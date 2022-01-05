import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class DialogEncryption extends StatelessWidget {
  const DialogEncryption({
    Key? key,
    this.content,
    this.onAccept,
  }) : super(key: key);

  final String? content;
  final Function? onAccept;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(Strings.titleDialogEncryption),
      contentPadding: Dimensions.dialogPadding,
      children: <Widget>[
        Text(
          content ?? Strings.confirmEncryption,
          textAlign: TextAlign.left,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SimpleDialogOption(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                Strings.buttonCancel,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            SimpleDialogOption(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              onPressed: () async {
                if (onAccept != null) {
                  await onAccept!();
                }

                Navigator.pop(context);
              },
              child: Text(
                Strings.buttonTextLetsEncrypt,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ],
        )
      ],
    );
  }
}

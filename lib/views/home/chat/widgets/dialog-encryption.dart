import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class DialogEncryption extends StatelessWidget {
  const DialogEncryption({
    Key? key,
    this.content = Strings.confirmationEncryption,
    this.onAccept,
  }) : super(key: key);

  final String content;
  final Function? onAccept;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        Strings.titleDialogEncryption,
      ),
      contentPadding: Dimensions.dialogPadding,
      children: <Widget>[
        Container(
          child: Text(
            content,
            textAlign: TextAlign.left,
          ),
          padding: Dimensions.dialogContentPadding,
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
                'cancel',
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
                'let\'s encrypt',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ],
        )
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';

class DialogConfirm extends StatelessWidget {
  const DialogConfirm({
    Key? key,
    this.title = '',
    this.content = '',
    this.confirm = Strings.buttonConfirm,
    this.onConfirm,
    this.onDismiss,
  }) : super(key: key);

  final String title;
  final String content;
  final String confirm;
  final Function? onConfirm;
  final Function? onDismiss;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        titlePadding: Dimensions.dialogPadding,
        contentPadding: Dimensions.dialogPadding,
        children: <Widget>[
          Text(content),
          Container(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ButtonText(
                  onPressed: () => onDismiss!(),
                  textWidget: Text(
                    Strings.buttonCancel,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                ButtonText(
                  onPressed: () => onConfirm!(),
                  textWidget: Text(
                    confirm,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            ),
          )
        ],
      );
}

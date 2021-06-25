import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class DialogInvite extends StatelessWidget {
  DialogInvite({
    Key? key,
    this.onAccept,
    this.onCancel,
  }) : super(key: key);

  final Function? onAccept;
  final Function? onCancel;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Accept Invite?'),
        contentPadding: Dimensions.dialogPadding,
        children: <Widget>[
          Container(
            child: Text(
              Strings.confirmationAcceptInvite,
              textAlign: TextAlign.left,
            ),
            padding: Dimensions.dialogContentPadding,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleDialogOption(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      }
                    },
                    child: Text(
                      'go back',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  SimpleDialogOption(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      if (onAccept != null) {
                        onAccept!();
                      }

                      Navigator.pop(context);
                    },
                    child: Text(
                      'accept',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      );
}

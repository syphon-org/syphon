import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:syphon/global/string-keys.dart';

class DialogInvite extends StatelessWidget {
  const DialogInvite({
    Key? key,
    this.onAccept,
    this.onReject,
    this.onCancel,
  }) : super(key: key);

  final Function? onAccept;
  final Function? onReject;
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
            padding: Dimensions.dialogContentPadding,
            child: Text(
              Strings.confirmationAcceptInvite,
              textAlign: TextAlign.left,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (onReject != null) {
                        onReject!();
                      }
                    },
                    child: Text(
                      'reject',
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

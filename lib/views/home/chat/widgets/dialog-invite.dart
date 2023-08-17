import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class DialogInvite extends StatelessWidget {
  const DialogInvite({
    super.key,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  final Function? onAccept;
  final Function? onReject;
  final Function? onCancel;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(Strings.titleDialogAcceptInvite),
        contentPadding: Dimensions.dialogPadding,
        children: <Widget>[
          Container(
            padding: Dimensions.dialogContentPadding,
            child: Text(
              Strings.confirmAcceptInvite,
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
                  onCancel?.call();
                },
                child: Text(
                  Strings.buttonTextGoBack,
                  style: Theme.of(context).textTheme.titleMedium,
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
                      onReject?.call();
                    },
                    child: Text(
                      Strings.buttonTextReject,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SimpleDialogOption(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      onAccept?.call();
                      Navigator.pop(context);
                    },
                    child: Text(
                      Strings.buttonTextAccept,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      );
}

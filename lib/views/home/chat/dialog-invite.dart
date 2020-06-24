import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:flutter/material.dart';

class DialogInvite extends StatelessWidget {
  final Function onAccept;

  DialogInvite({
    Key key,
    this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
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
            SimpleDialogOption(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(
                'block',
                style: Theme.of(context).textTheme.subtitle1,
              ),
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
                    Navigator.popUntil(context, (route) => route.isFirst);
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
                      onAccept();
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
}

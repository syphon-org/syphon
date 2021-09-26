import 'dart:io';

import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

class ChatScreenArguments {
  final File? file;
  final String? roomId;

  // Improve loading times
  ChatScreenArguments({this.roomId, this.file});
}

class ChatMediaPreviewScreen extends StatelessWidget {
  const ChatMediaPreviewScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: Dimensions.dialogPadding,
        children: <Widget>[
          Container(
            padding: Dimensions.dialogContentPadding,
            child: Text(
              Strings.confirmAcceptInvite,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      );
}

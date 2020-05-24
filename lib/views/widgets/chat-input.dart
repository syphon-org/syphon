import 'package:Tether/global/colors.dart';
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/formatters.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/image-matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/**
 * RoundedPopupMenu
 * Mostly an example for myself on how to override styling or other options on
 * existing components app wide
 */
class ChatInput extends StatelessWidget {
  final bool sendable;
  final FocusNode focusNode;
  final TextEditingController controller;

  final Function onChangeMessage;
  final Function onSubmitMessage;
  final Function onSubmittedMessage;

  ChatInput({
    Key key,
    this.sendable,
    this.focusNode,
    this.controller,
    this.onChangeMessage,
    this.onSubmitMessage,
    this.onSubmittedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double messageInputWidth = width - 72;

    Color inputTextColor = const Color(BASICALLY_BLACK);
    Color inputColorBackground = const Color(ENABLED_GREY);
    Color inputCursorColor = Colors.blueGrey;
    Color sendButtonColor = const Color(DISABLED_GREY);

    if (sendable) {
      sendButtonColor = Theme.of(context).primaryColor;
    }

    if (Theme.of(context).brightness == Brightness.dark) {
      inputTextColor = Colors.white;
      inputColorBackground = Colors.blueGrey;
      inputCursorColor = Colors.white;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(
            maxWidth: messageInputWidth,
          ),
          child: TextField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            cursorColor: inputCursorColor,
            focusNode: focusNode,
            controller: controller,
            // onChanged: (text) => onUpdateMessage(text, props),
            // onSubmitted:
            //     !sendable ? null : (text) => this.onSubmitMessage(props),
            onChanged: onChangeMessage != null ? onChangeMessage : null,
            onSubmitted: !sendable ? null : onSubmittedMessage,
            style: TextStyle(
              height: 1.5,
              color: inputTextColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputColorBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              hintText: 'Matrix message (unencrypted)',
            ),
          ),
        ),
        Container(
          width: 48.0,
          padding: EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: !sendable ? null : onSubmitMessage,
            child: CircleAvatar(
              backgroundColor: sendButtonColor,
              child: Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

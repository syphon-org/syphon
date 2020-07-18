import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/**
 * RoundedPopupMenu
 * Mostly an example for myself on how to override styling or other options on
 * existing components app wide
 */
class ChatInput extends StatelessWidget {
  final bool sendable;
  final String mediumType;
  final FocusNode focusNode;
  final TextEditingController controller;

  final Function onChangeMessage;
  final Function onSubmitMessage;
  final Function onSubmittedMessage;
  final Function onChangeMethod;

  ChatInput({
    Key key,
    this.sendable,
    this.focusNode,
    this.mediumType,
    this.controller,
    this.onChangeMessage,
    this.onChangeMethod,
    this.onSubmitMessage,
    this.onSubmittedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double messageInputWidth = width - 72;

    Color inputTextColor = const Color(Colours.blackDefault);
    Color inputColorBackground = const Color(Colours.greyEnabled);
    Color inputCursorColor = Colors.blueGrey;
    Color sendButtonColor = const Color(Colours.greyDisabled);
    String hintText = Strings.placeholderInputMatrixUnencrypted;

    if (mediumType == MediumType.plaintext) {
      if (sendable) {
        sendButtonColor = Theme.of(context).accentColor;
      }
    }

    if (mediumType == MediumType.encryption) {
      hintText = Strings.placeholderInputMatrixEncrypted;

      if (sendable) {
        sendButtonColor = Theme.of(context).primaryColor;
      }
    }

    if (Theme.of(context).brightness == Brightness.dark) {
      inputTextColor = Colors.white;
      inputColorBackground = Colors.blueGrey;
      inputCursorColor = Colors.white;
    }

    // Default, but shouldn't be used
    Widget sendButton = InkWell(
      borderRadius: BorderRadius.circular(48),
      onLongPress: onChangeMethod,
      onTap: !sendable ? null : onSubmitMessage,
      child: CircleAvatar(
        backgroundColor: sendButtonColor,
        child: Icon(
          Icons.send,
          color: Colors.white,
        ),
      ),
    );

    if (mediumType == MediumType.plaintext) {
      sendButton = InkWell(
        borderRadius: BorderRadius.circular(48),
        onLongPress: onChangeMethod,
        onTap: !sendable ? null : onSubmitMessage,
        child: CircleAvatar(
          backgroundColor: sendButtonColor,
          child: Stack(children: [
            Positioned(
              right: 0,
              bottom: -1.5,
              child: Icon(
                Icons.lock_open,
                size: Dimensions.miniLockSize,
                color: Colors.white,
              ),
            ),
            Icon(
              Icons.send,
              size: Dimensions.iconSizeLite,
              color: Colors.white,
            ),
          ]),
        ),
      );
    }

    if (mediumType == MediumType.encryption) {
      sendButton = InkWell(
        borderRadius: BorderRadius.circular(48),
        onLongPress: onChangeMethod,
        onTap: !sendable ? null : onSubmitMessage,
        child: CircleAvatar(
          backgroundColor: sendButtonColor,
          child: Stack(children: [
            Positioned(
              right: 0,
              bottom: -1.5,
              child: Icon(
                Icons.lock,
                size: Dimensions.miniLockSize,
                color: Colors.white,
              ),
            ),
            Icon(
              Icons.send,
              size: Dimensions.iconSizeLite,
              color: Colors.white,
            ),
          ]),
        ),
      );
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
              hintText: hintText,
            ),
          ),
        ),
        Container(
          width: 48.0,
          padding: EdgeInsets.symmetric(vertical: 4),
          child: sendButton,
        ),
      ],
    );
  }
}

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syphon/global/assets.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class ChatInput extends StatelessWidget {
  final bool sendable;
  final bool enterSend;
  final Message quotable;
  final String mediumType;
  final FocusNode focusNode;
  final TextEditingController controller;

  final Function onChangeMessage;
  final Function onSubmitMessage;
  final Function onSubmittedMessage;
  final Function onChangeMethod;
  final Function onCancelReply;

  ChatInput({
    Key key,
    this.sendable,
    this.focusNode,
    this.mediumType,
    this.controller,
    this.quotable,
    this.enterSend = false,
    this.onChangeMessage,
    this.onChangeMethod,
    this.onSubmitMessage,
    this.onSubmittedMessage,
    this.onCancelReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    double messageInputWidth = width - 72;

    final bool replying = quotable != null && quotable.sender != null;

    final maxHeight = replying ? height * 0.8 : height * 0.75;

    Color inputTextColor = const Color(Colours.blackDefault);
    Color inputColorBackground = const Color(Colours.greyEnabled);
    Color inputCursorColor = Colors.blueGrey;
    Color sendButtonColor = const Color(Colours.greyDisabled);
    String hintText = Strings.placeholderInputMatrixUnencrypted;

    if (mediumType == MediumType.plaintext) {
      if (sendable) {
        if (Theme.of(context).accentColor != Theme.of(context).primaryColor) {
          sendButtonColor = Theme.of(context).accentColor;
        } else {
          sendButtonColor = Colors.grey[700];
        }
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
      inputCursorColor = Colors.white;
      inputColorBackground = Colors.blueGrey;
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
          child: Container(
            margin: EdgeInsets.only(left: 2, top: 3),
            child: SvgPicture.asset(
              Assets.iconSendUnlockBeing,
              color: Colors.white,
              semanticsLabel: Strings.semanticsSendUnencrypted,
            ),
          ),
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
          child: Container(
            margin: EdgeInsets.only(left: 2, top: 3),
            child: SvgPicture.asset(
              Assets.iconSendLockSolidBeing,
              color: Colors.white,
              semanticsLabel: Strings.semanticsSendUnencrypted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Visibility(
          visible: replying,
          maintainSize: false,
          maintainState: false,
          maintainAnimation: false,
          child: Row(
            //////// REPLY FIELD ////////
            children: <Widget>[
              Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: messageInputWidth,
                    ),
                    child: TextField(
                      maxLines: 1,
                      enabled: false,
                      autocorrect: false,
                      enableSuggestions: false,
                      controller: TextEditingController(
                        text: replying ? quotable.body : '',
                      ),
                      style: TextStyle(
                        color: inputTextColor,
                      ),
                      decoration: InputDecoration(
                        labelText: replying ? quotable.sender : '',
                        labelStyle:
                            TextStyle(color: Theme.of(context).accentColor),
                        filled: true,
                        contentPadding: Dimensions.inputContentPadding,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).accentColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(!replying ? 24 : 0),
                            bottomRight: Radius.circular(!replying ? 24 : 0),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).accentColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(!replying ? 24 : 0),
                            bottomRight: Radius.circular(!replying ? 24 : 0),
                          ),
                        ),
                        hintText: hintText,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      onPressed: () => onCancelReply(),
                      icon: Icon(
                        Icons.close,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        Row(
          //////// ACTUAL INPUT FIELD ////////
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                maxWidth: messageInputWidth,
              ),
              child: Container(
                child: TextField(
                  maxLines: null,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.multiline,
                  textInputAction: enterSend
                      ? TextInputAction.send
                      : TextInputAction.newline,
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
                    contentPadding: Dimensions.inputContentPadding,
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).accentColor, width: 1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(!replying ? 24 : 0),
                          topRight: Radius.circular(!replying ? 24 : 0),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        )),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(!replying ? 24 : 0),
                      topRight: Radius.circular(!replying ? 24 : 0),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    )),
                    hintText: hintText,
                  ),
                ),
              ),
            ),
            Container(
              width: Dimensions.buttonSendSize,
              padding: EdgeInsets.symmetric(vertical: 4),
              child: sendButton,
            ),
          ],
        )
      ],
    );
  }
}

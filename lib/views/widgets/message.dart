import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/formatters.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/image-matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageWidget extends StatelessWidget {
  MessageWidget({
    Key key,
    @required this.message,
    this.onLongPress,
    this.isUserSent,
    this.messageOnly = false,
    this.isLastSender = false,
    this.isNextSender = false,
    this.lastRead = 0,
    this.selectedMessageId,
    this.avatarUri,
    this.theme = ThemeType.LIGHT,
  }) : super(key: key);

  final Message message;
  final bool isLastSender;
  final bool isNextSender;
  final bool isUserSent;
  final bool messageOnly;
  final int lastRead;
  final ThemeType theme;
  final String selectedMessageId;
  final Function onLongPress;
  final String avatarUri;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    var textColor = Colors.white;
    double indicatorSize = 14;

    var showSender = true;
    var indicatorColor = Colors.white;
    var indicatorIconColor = Colors.white;
    var bubbleColor = hashedColor(message.sender);
    var bubbleBorder = BorderRadius.circular(16);
    var messageAlignment = MainAxisAlignment.start;
    var messageTextAlignment = CrossAxisAlignment.start;
    var bubbleSpacing = EdgeInsets.symmetric(vertical: 8);
    var opacity = 1.0;
    var isRead = message.timestamp < lastRead;

    // CURRENT USER SENT STYLING
    if (isUserSent) {
      if (isLastSender) {
        if (isNextSender) {
          // Message in the middle of a sender messages block
          bubbleSpacing = EdgeInsets.symmetric(vertical: 2);
          bubbleBorder = BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          );
        } else {
          // Message at the beginning of a user sender messages block
          bubbleSpacing = EdgeInsets.only(top: 8, bottom: 2);
          bubbleBorder = BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          );
        }
      }

      if (!isLastSender && isNextSender) {
        // End of a sender messages block
        bubbleSpacing = EdgeInsets.only(top: 2, bottom: 8);
        bubbleBorder = BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
      }
      // OTHER USER SENT STYLING
    } else {
      if (isLastSender) {
        if (isNextSender) {
          // Message in the middle of a sender messages block
          bubbleSpacing = EdgeInsets.symmetric(vertical: 2);
          bubbleBorder = BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );
          showSender = false;
        } else {
          // Message at the beginning of a sender messages block
          bubbleSpacing = EdgeInsets.only(top: 8, bottom: 2);
          bubbleBorder = BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );
        }
      }

      if (!isLastSender && isNextSender) {
        // End of a sender messages block
        bubbleSpacing = EdgeInsets.only(top: 2, bottom: 8);
        bubbleBorder = BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
      }
    }

    if (isUserSent) {
      textColor = theme != ThemeType.LIGHT ? Colors.white : Color(GREY_DARK);
      if (theme == ThemeType.DARK) {
        bubbleColor = Colors.grey[700];
      } else if (theme == ThemeType.DARKER) {
        bubbleColor = Colors.grey[850];
      } else {
        bubbleColor = const Color(GREY_BUBBLE);
      }

      indicatorColor = isRead ? textColor : bubbleColor;
      indicatorIconColor = isRead ? bubbleColor : textColor;

      messageAlignment = MainAxisAlignment.end;
      messageTextAlignment = CrossAxisAlignment.end;
    }

    if (selectedMessageId != null) {
      opacity = selectedMessageId == message.id ? 1 : 0.5;
    }

    String body = message.body;
    if (message.type == EventTypes.encrypted) {
      if (message.body.isEmpty) {
        body = Strings.contentEncryptedMessage;
      }
    }

    return GestureDetector(
      onLongPress: () {
        if (this.onLongPress != null) {
          HapticFeedback.lightImpact();
          this.onLongPress(message: message);
        }
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: bubbleSpacing,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: messageAlignment,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Visibility(
                      visible: !isLastSender && !isUserSent && !messageOnly,
                      maintainState: !messageOnly,
                      maintainAnimation: !messageOnly,
                      maintainSize: !messageOnly,
                      child: Container(
                        margin: const EdgeInsets.only(
                          right: 8,
                        ),
                        child: avatarUri != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.thumbnailSizeMax,
                                ),
                                child: MatrixImage(
                                  width: Dimensions.avatarSizeMessage,
                                  height: Dimensions.avatarSizeMessage,
                                  mxcUri: avatarUri,
                                ),
                              )
                            : CircleAvatar(
                                radius: 14,
                                backgroundColor: bubbleColor,
                                child: Text(
                                  formatSenderInitials(message.sender),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: bubbleBorder,
                        ),
                        child: Flex(
                          direction: Axis.vertical,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: messageTextAlignment,
                          children: <Widget>[
                            Visibility(
                              visible: !isUserSent && showSender,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  formatSender(message.sender),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 5),
                              child: Text(
                                body.trim(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            Flex(
                              // *** Message Status Row ***
                              direction: Axis.horizontal,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: messageTextAlignment,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(right: 4),
                                  child: Text(
                                    message.failed
                                        ? 'Message failed to send'
                                        : formatTimestamp(
                                            lastUpdateMillis: message.timestamp,
                                            showTime: true,
                                          ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: message.type == EventTypes.encrypted,
                                  child: Container(
                                    width: indicatorSize,
                                    height: indicatorSize,
                                    margin: EdgeInsets.only(left: 2),
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: Colors.white,
                                      size: Dimensions.miniLockSize,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: isUserSent && message.failed,
                                  child: Container(
                                    width: indicatorSize,
                                    height: indicatorSize,
                                    margin: EdgeInsets.only(left: 3),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.redAccent,
                                      size: Dimensions.indicatorSize,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: isUserSent && !message.failed,
                                  child: Stack(children: [
                                    Visibility(
                                      visible: message.pending,
                                      child: Container(
                                        width: indicatorSize,
                                        height: indicatorSize,
                                        margin: EdgeInsets.only(left: 4),
                                        child: CircularProgressIndicator(
                                          strokeWidth:
                                              Dimensions.defaultStrokeWidthLite,
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: !message.pending,
                                      child: Container(
                                        width: indicatorSize,
                                        height: indicatorSize,
                                        margin: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.check,
                                          size: 10,
                                          color: indicatorIconColor,
                                        ),
                                        decoration: ShapeDecoration(
                                          color: indicatorColor,
                                          shape: CircleBorder(
                                            side: BorderSide(
                                              color: indicatorIconColor,
                                              width: isRead ? 1.5 : 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: !message.syncing,
                                      child: Container(
                                        width: indicatorSize,
                                        height: indicatorSize,
                                        margin: EdgeInsets.only(left: 11),
                                        child: Icon(
                                          Icons.check,
                                          size: 10,
                                          color: indicatorIconColor,
                                        ),
                                        decoration: ShapeDecoration(
                                          color: indicatorColor,
                                          shape: CircleBorder(
                                            side: BorderSide(
                                              color: indicatorIconColor,
                                              width: isRead ? 1.5 : 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

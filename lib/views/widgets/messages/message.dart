// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';

class MessageWidget extends StatelessWidget {
  MessageWidget({
    Key key,
    @required this.message,
    this.onLongPress,
    this.onPressAvatar,
    this.isUserSent,
    this.messageOnly = false,
    this.isLastSender = false,
    this.isNextSender = false,
    this.lastRead = 0,
    this.selectedMessageId,
    this.avatarUri,
    this.theme = ThemeType.LIGHT,
    this.timeFormat = '12hr',
  }) : super(key: key);

  final Message message;
  final bool isLastSender;
  final bool isNextSender;
  final bool isUserSent;
  final bool messageOnly;
  final int lastRead;
  final String timeFormat;
  final ThemeType theme;
  final String selectedMessageId;
  final Function onLongPress;
  final Function onPressAvatar;
  final String avatarUri;

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    var textColor = Colors.white;
    var showSender = true;
    var indicatorColor = Theme.of(context).iconTheme.color;
    var indicatorIconColor = Theme.of(context).iconTheme.color;
    var bubbleColor = Colours.hashedColor(message.sender);
    var bubbleBorder = BorderRadius.circular(16);
    var messageAlignment = MainAxisAlignment.start;
    var messageTextAlignment = CrossAxisAlignment.start;
    var bubbleSpacing = EdgeInsets.symmetric(vertical: 8);
    var opacity = 1.0;
    var isRead = message.timestamp < lastRead;

    // Current User Bubble Styling
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
      // External User Sent Styling
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
      if (theme == ThemeType.DARK) {
        bubbleColor = Colors.grey[700];
      } else if (theme != ThemeType.LIGHT) {
        bubbleColor = Colors.grey[850];
      } else {
        textColor = const Color(Colours.blackFull);
        bubbleColor = const Color(Colours.greyBubble);
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
                      child: GestureDetector(
                        onTap: () {
                          if (this.onPressAvatar != null) {
                            HapticFeedback.lightImpact();
                            this.onPressAvatar(message: message);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: AvatarCircle(
                            margin: EdgeInsets.zero,
                            padding: EdgeInsets.zero,
                            uri: avatarUri,
                            alt: message.sender,
                            size: Dimensions.avatarSizeMessage,
                            background: Colours.hashedColor(message.sender),
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
                                Visibility(
                                  visible: !isUserSent &&
                                      message.type == EventTypes.encrypted,
                                  child: Container(
                                    width: Dimensions.indicatorSize,
                                    height: Dimensions.indicatorSize,
                                    margin: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.lock,
                                      color: textColor,
                                      size: Dimensions.iconSizeMini,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 4),
                                  child: Text(
                                    message.failed
                                        ? Strings.errorMessageSendingFailed
                                        : formatTimestamp(
                                            lastUpdateMillis: message.timestamp,
                                            timeFormat: timeFormat,
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
                                  visible: isUserSent &&
                                      message.type == EventTypes.encrypted,
                                  child: Container(
                                    width: Dimensions.indicatorSize,
                                    height: Dimensions.indicatorSize,
                                    margin: EdgeInsets.only(left: 2),
                                    child: Icon(
                                      Icons.lock,
                                      color: textColor,
                                      size: Dimensions.iconSizeMini,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: isUserSent && message.failed,
                                  child: Container(
                                    width: Dimensions.indicatorSize,
                                    height: Dimensions.indicatorSize,
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
                                        width: Dimensions.indicatorSize,
                                        height: Dimensions.indicatorSize,
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
                                        width: Dimensions.indicatorSize,
                                        height: Dimensions.indicatorSize,
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
                                        width: Dimensions.indicatorSize,
                                        height: Dimensions.indicatorSize,
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

import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/formatters.dart';
import 'package:Tether/global/themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/**
 * RoundedPopupMenu
 * Mostly an example for myself on how to override styling or other options on
 * existing components app wide
 */
class MessageWidget extends StatelessWidget {
  MessageWidget({
    Key key,
    @required this.message,
    this.isUserSent,
    this.isLastSender,
    this.isNextSender,
    this.theme = ThemeType.LIGHT,
  }) : super(key: key);

  final Message message;
  final bool isLastSender;
  final bool isNextSender;
  final bool isUserSent;
  final ThemeType theme;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    var textColor = Colors.white;
    var bubbleColor = hashedColor(message.sender);
    var bubbleBorder = BorderRadius.circular(16);
    var messageAlignment = MainAxisAlignment.start;
    var messageTextAlignment = CrossAxisAlignment.start;
    var bubbleSpacing = EdgeInsets.symmetric(vertical: 8);

    if (isLastSender) {
      if (isNextSender) {
        // Message in the middle of a sender messages block
        bubbleSpacing = EdgeInsets.symmetric(vertical: 2);
        bubbleBorder = BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        );
      } else {
        // Message at the beginning of a sender messages block
        bubbleSpacing = EdgeInsets.only(top: 8, bottom: 2);
        bubbleBorder = BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        );
      }
    }

    if (!isLastSender && isNextSender) {
      // End of a sender messages block
      bubbleSpacing = EdgeInsets.only(top: 2, bottom: 8);
      bubbleBorder = BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        topLeft: Radius.circular(4),
      );
    }

    if (isUserSent) {
      textColor = theme != ThemeType.LIGHT ? Colors.white : GREY_DARK_COLOR;
      messageAlignment = MainAxisAlignment.end;
      messageTextAlignment = CrossAxisAlignment.end;

      if (theme == ThemeType.DARK) {
        bubbleColor = Colors.grey[700];
      } else if (theme == ThemeType.DARKER) {
        bubbleColor = Colors.grey[850];
      } else {
        bubbleColor = ENABLED_GREY_COLOR;
      }
    }

    return Container(
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
            // decoration: BoxDecoration( // DEBUG ONLY
            //   color: Colors.red,
            // ),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: messageAlignment,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Visibility(
                  visible: !isLastSender && !isUserSent,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: Container(
                    margin: const EdgeInsets.only(
                      right: 12,
                    ),
                    child: CircleAvatar(
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
                          visible: !isUserSent,
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
                            message.body.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Flex(
                          direction: Axis.horizontal,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: messageTextAlignment,
                          children: [
                            Container(
                              child: Text(
                                formatTimestamp(
                                  lastUpdateMillis: message.timestamp,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                            ),
                            Visibility(
                              visible: isUserSent,
                              child: Stack(children: [
                                Visibility(
                                    visible: !message.pending,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      margin: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.check,
                                        size: 10,
                                        color: bubbleColor,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: CircleBorder(
                                          side: BorderSide(
                                            color: bubbleColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    )),
                                Visibility(
                                  visible: !message.syncing,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    margin: EdgeInsets.only(left: 11),
                                    child: Icon(
                                      Icons.check,
                                      size: 10,
                                      color: bubbleColor,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: CircleBorder(
                                        side: BorderSide(
                                          color: bubbleColor,
                                          width: 1.5,
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
    );
  }
}

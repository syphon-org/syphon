// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syphon/global/colours.dart';

// Project imports:
import 'package:syphon/store/user/model.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class MessageTypingWidget extends StatefulWidget {
  final bool typing;
  final List<String> usersTyping;
  final Map<String, User> roomUsers;
  final String selectedMessageId;
  final Function onPressAvatar;

  MessageTypingWidget({
    Key key,
    this.typing,
    this.usersTyping,
    this.roomUsers,
    this.selectedMessageId,
    this.onPressAvatar,
  }) : super(key: key);

  @override
  MessageTypingState createState() => MessageTypingState();
}

/**
 * RoundedPopupMenu
 * Mostly an example for myself on how to override styling or other options on
 * existing components app wide
 */
class MessageTypingState extends State<MessageTypingWidget>
    with TickerProviderStateMixin {
  double fullSize = 1;

  @protected
  wrapAnimation({Widget animatedWidget, int milliseconds}) =>
      TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: widget.typing ? 1 : 0),
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: animatedWidget,
        builder: (BuildContext context, double size, Widget child) =>
            GestureDetector(
          onTap: () => setState(() {
            fullSize = fullSize == 1 ? 0.0 : 1;
          }),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: Dimensions.bubbleWidthMin * size,
              maxHeight: Dimensions.bubbleHeightMin * size,
            ),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    var textColor = Colors.white;
    var bubbleColor = Theme.of(context).primaryColor;

    var bubbleBorder = BorderRadius.circular(16);
    var messageAlignment = MainAxisAlignment.start;
    var messageTextAlignment = CrossAxisAlignment.start;
    var opacity = 1.0;

    var bubbleSpacing = EdgeInsets.only(top: 4, bottom: 4);
    var userTyping = User();

    bubbleBorder = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    );

    if (widget.selectedMessageId != null) {
      opacity = widget.selectedMessageId != null ? 0.5 : 1.0;
    }

    if (widget.usersTyping.length > 0) {
      final usernamesTyping = widget.usersTyping;
      userTyping = widget.roomUsers[usernamesTyping[0]];
    }

    return Opacity(
      opacity: opacity,
      child: wrapAnimation(
        milliseconds: 225,
        animatedWidget: Container(
          child: Flex(
            direction: Axis.vertical,
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
                      visible: userTyping.avatarUri != null,
                      maintainSize: true,
                      maintainState: true,
                      maintainAnimation: true,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onPressAvatar != null) {
                            HapticFeedback.lightImpact();
                            widget.onPressAvatar(userId: userTyping.userId);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: userTyping.userId == null
                              ? null
                              : Avatar(
                                  uri: userTyping.avatarUri,
                                  alt: userTyping.displayName ??
                                      userTyping.userId,
                                  size: Dimensions.avatarSizeMessage,
                                  background: Colours.hashedColor(
                                    userTyping.userId ?? '',
                                  ),
                                ),
                        ),
                      ),
                    ),
                    wrapAnimation(
                      milliseconds: 175,
                      animatedWidget: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: bubbleBorder,
                        ),
                        child: Flex(
                          direction: Axis.horizontal,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: messageTextAlignment,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

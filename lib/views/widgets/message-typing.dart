import 'package:Tether/global/dimensions.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/formatters.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/image-matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/**
 * RoundedPopupMenu
 * Mostly an example for myself on how to override styling or other options on
 * existing components app wide
 */
class MessageTypingWidget extends StatelessWidget {
  final bool isLastSender;
  final bool isNextSender;
  final bool isUserSent;
  final int lastRead;
  final ThemeType theme;
  final String selectedMessageId;
  final String avatarUri;
  final String typer;

  MessageTypingWidget({
    Key key,
    this.isUserSent = false,
    this.isLastSender = false,
    this.isNextSender = false,
    this.lastRead = 0,
    this.selectedMessageId,
    this.theme = ThemeType.LIGHT,
    this.avatarUri,
    this.typer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var textColor = Colors.white;
    var bubbleColor = Theme.of(context).primaryColor;

    var bubbleBorder = BorderRadius.circular(16);
    var messageAlignment = MainAxisAlignment.start;
    var messageTextAlignment = CrossAxisAlignment.start;
    var opacity = 1.0;

    // TODO: allow for displaying specific users typing
    var bubbleSpacing = EdgeInsets.only(top: 4, bottom: 4);

    bubbleBorder = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    );

    if (selectedMessageId != null) {
      opacity = selectedMessageId != null ? 0.5 : 1.0;
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: Dimensions.bubbleWidthMin,
          minHeight: Dimensions.bubbleHeightMin,
        ),
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
                    visible: false,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
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
                                formatSenderInitials(typer ?? 'fake guy'),
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
                            margin: EdgeInsets.symmetric(horizontal: 8),
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
                            margin: EdgeInsets.symmetric(horizontal: 8),
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
                            margin: EdgeInsets.symmetric(horizontal: 8),
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
    );
  }
}

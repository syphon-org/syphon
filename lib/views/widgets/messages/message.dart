import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swipeable/swipeable.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/image-matrix.dart';
import 'package:syphon/views/widgets/input/text-field-edit.dart';
import 'package:syphon/views/widgets/messages/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    Key? key,
    required this.message,
    this.isUserSent = false,
    this.messageOnly = false,
    this.isLastSender = false,
    this.isNextSender = false,
    this.isEditing = false,
    this.lastRead = 0,
    this.selectedMessageId,
    this.avatarUri,
    this.displayName,
    this.themeType = ThemeType.Light,
    this.fontSize = 14.0,
    this.timeFormat = '12hr',
    this.color,
    this.onSendEdit,
    this.onLongPress,
    this.onPressAvatar,
    this.onInputReaction,
    this.onToggleReaction,
    this.onSwipe,
  }) : super(key: key);

  final bool messageOnly;
  final bool isLastSender;
  final bool isNextSender;
  final bool isUserSent;
  final bool isEditing;

  final int lastRead;
  final double fontSize;
  final String timeFormat;
  final String? avatarUri;
  final String? selectedMessageId;
  final String? displayName;
  final Color? color;

  final Message message;
  final ThemeType themeType;

  final Function? onSwipe;
  final Function? onSendEdit;
  final Function? onPressAvatar;
  final Function? onInputReaction;
  final Function? onToggleReaction;
  final void Function(Message)? onLongPress;

  buildReactions(BuildContext context, MainAxisAlignment alignment) {
    final reactionsMap = message.reactions.fold<Map<String, int>>(
      {},
      (mapped, reaction) => mapped
        ..update(
          reaction.body ?? '',
          (value) => (value + 1),
          ifAbsent: () => 1,
        ),
    );

    final reactionKeys = reactionsMap.keys.toList();
    final reactionCounts = reactionsMap.values.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      itemCount: reactionKeys.length,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.antiAlias,
      itemBuilder: (BuildContext context, int index) {
        final reactionKey = reactionKeys[index];
        final reactionCount = reactionCounts[index];
        return GestureDetector(
          onTap: () {
            if (onToggleReaction != null) {
              onToggleReaction!(reactionKey);
            }
          },
          child: Container(
            width: reactionCount > 1 ? 48 : 32,
            height: 48,
            decoration: BoxDecoration(
              color: Color(Colours.greyDefault),
              borderRadius: BorderRadius.circular(Dimensions.iconSize),
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reactionKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.subtitle1!.color,
                    height: 1.35,
                  ),
                ),
                Visibility(
                  visible: reactionCount > 1,
                  child: Container(
                    padding: EdgeInsets.only(left: 3),
                    child: Text(
                      reactionCount.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.subtitle1!.color,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  buildReactionsInput(BuildContext context, MainAxisAlignment alignment, bool isUserSent) {
    final buildEmojiButton = GestureDetector(
      onTap: () {
        if (onInputReaction != null) {
          onInputReaction!();
        }
      },
      child: ClipRRect(
        child: Container(
          width: 36,
          height: Dimensions.iconSizeLarge,
          decoration: BoxDecoration(
            color: Color(Colours.greyDefault),
            borderRadius: BorderRadius.circular(Dimensions.iconSizeLarge),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.tag_faces,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );

    // swaps order in row if user sent
    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isUserSent
          ? [
              buildEmojiButton,
              buildReactions(context, alignment),
            ]
          : [
              buildReactions(context, alignment),
              buildEmojiButton,
            ],
    );
  }

  onSwipeMessage(Message message) {
    if (onSwipe != null) {
      onSwipe!(message);
    }
  }

  onConfirmLink(BuildContext context, String? url) {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.titleDialogConfirmLinkout.capitalize(),
        content: Strings.confirmLinkout(url!),
        confirmStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
        confirmText: Strings.buttonConfirmFormal.capitalize(),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();

          if (await canLaunch(url)) {
            return launch(url, forceSafariVC: false);
          } else {
            throw 'Could not launch $url';
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final selected = selectedMessageId != null && selectedMessageId == message.id;

    // emoji input button needs space
    final hasReactions = message.reactions.isNotEmpty || selected;
    final isRead = message.timestamp < lastRead;
    final showAvatar = !isLastSender && !isUserSent && !messageOnly;

    final isImage = message.msgtype == MatrixMessageTypes.image;
    final isFile = message.msgtype == MatrixMessageTypes.file;
    final isMedia = message.url != null;
    final removePadding = isMedia || (isEditing && selected);

    var textColor = Colors.white;
    var showSender = !messageOnly && !isUserSent; // nearly always show the sender

    var indicatorColor = Theme.of(context).iconTheme.color;
    var indicatorIconColor = Theme.of(context).iconTheme.color;
    var replyColor = color;
    var bubbleColor = color ?? Colours.hashedColor(message.sender);
    var bubbleBorder = BorderRadius.circular(16);
    var alignmentMessage = MainAxisAlignment.start;
    var alignmentReaction = MainAxisAlignment.start;
    var alignmentMessageText = CrossAxisAlignment.start;
    var bubbleSpacing = EdgeInsets.symmetric(vertical: 4);
    var showStatus = true;

    var fontStyle;
    var opacity = 1.0;
    var zIndex = 1.0;
    var status = timeFormat == 'full'
        ? formatTimestampFull(
            lastUpdateMillis: message.timestamp,
            timeFormat: timeFormat,
            showTime: true,
          )
        : formatTimestamp(
            lastUpdateMillis: message.timestamp,
            timeFormat: timeFormat,
            showTime: true,
          );

    // Current User Bubble Styling
    if (isUserSent) {
      if (isLastSender) {
        if (isNextSender) {
          // Message in the middle of a sender messages block
          bubbleSpacing = EdgeInsets.symmetric(vertical: 2);
          bubbleBorder = Styles.bubbleBorderMiddleUser;
          showStatus = false;
        } else {
          // Message at the beginning of a user sender messages block
          bubbleSpacing = EdgeInsets.only(top: 8, bottom: 2);
          bubbleBorder = Styles.bubbleBorderTopUser;
          showStatus = false;
        }
      }

      if (!isLastSender && isNextSender) {
        // End of a sender messages block
        bubbleSpacing = EdgeInsets.only(top: 2, bottom: 8);
        bubbleBorder = Styles.bubbleBorderBottomUser;
      }
      // External User Sent Styling
    } else {
      if (isLastSender) {
        if (isNextSender) {
          // Message in the middle of a sender messages block
          bubbleSpacing = EdgeInsets.symmetric(vertical: 2);
          bubbleBorder = Styles.bubbleBorderMiddleSender;
          showSender = false;
        } else {
          // Message at the beginning of a sender messages block
          bubbleSpacing = EdgeInsets.only(top: 8, bottom: 2);
          bubbleBorder = Styles.bubbleBorderTopSender;
        }
      }

      if (!isLastSender && isNextSender) {
        // End of a sender messages block
        bubbleSpacing = EdgeInsets.only(top: 2, bottom: 8);
        bubbleBorder = Styles.bubbleBorderBottomSender;
      }
    }

    if (isUserSent) {
      if (themeType == ThemeType.Dark) {
        bubbleColor = Color(Colours.greyDark);
      } else if (themeType != ThemeType.Light) {
        bubbleColor = Color(Colours.greyDarkest);
      } else {
        textColor = const Color(Colours.blackFull);
        bubbleColor = const Color(Colours.greyLightest);
      }

      indicatorColor = isRead ? textColor : bubbleColor;
      indicatorIconColor = isRead ? bubbleColor : textColor;

      alignmentMessage = MainAxisAlignment.end;
      alignmentReaction = MainAxisAlignment.start;
      alignmentMessageText = CrossAxisAlignment.end;
    } else {
      textColor = bubbleColor.computeLuminance() > 0.6 ? Colors.black : Colors.white;
    }

    if (selectedMessageId != null && !selected) {
      opacity = 0.5;
      zIndex = -10.0;
    }

    if (message.failed) {
      status = Strings.alertMessageSendingFailed;
      showStatus = true;
    }

    if (message.edited) {
      status += ' (Edited)';
    }

    String body = message.body ?? '';

    // efficent way to check if Matrix message is a reply
    if (body.length > 1 && body[0] == '>') {
      final isLight = bubbleColor.computeLuminance() > 0.5;
      replyColor = HSLColor.fromColor(bubbleColor).withLightness(isLight ? 0.85 : 0.25).toColor();
    }

    if (message.type == EventTypes.encrypted) {
      if (message.body!.isEmpty) {
        body = Strings.labelEncryptedMessage;
      }
    } else {
      if (message.body!.isEmpty) {
        body = Strings.labelDeletedMessage;
        fontStyle = FontStyle.italic;
      }
    }

    if (message.body == null) {
      body = Strings.labelDeletedMessage;
    }

    return Swipeable(
      onSwipeLeft: isUserSent ? () => onSwipeMessage(message) : () => {},
      onSwipeRight: !isUserSent ? () => onSwipeMessage(message) : () => {},
      background: Positioned(
        top: 0,
        bottom: 0,
        left: !isUserSent ? 0 : null,
        right: isUserSent ? 0 : null,
        child: Opacity(
          // HACK: hide the reply icon under the message
          opacity: opacity == 0.5 ? 0 : 1,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isUserSent ? 24 : 50,
            ),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: alignmentMessage,
              // ignore: avoid_redundant_argument_values
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.reply, size: Dimensions.iconSizeLarge),
              ],
            ),
          ),
        ),
      ),
      child: GestureDetector(
        onLongPress: () {
          if (onLongPress != null) {
            HapticFeedback.lightImpact();
            onLongPress!(message);
          }
        },
        child: Opacity(
          opacity: opacity,
          child: Container(
            transform: Matrix4.translationValues(0.0, 0.0, zIndex),
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: bubbleSpacing, // spacing between different user bubbles
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: alignmentMessage,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Visibility(
                        visible: showAvatar,
                        maintainState: !messageOnly,
                        maintainAnimation: !messageOnly,
                        maintainSize: !messageOnly,
                        child: GestureDetector(
                          onTap: () {
                            if (onPressAvatar != null) {
                              HapticFeedback.lightImpact();
                              onPressAvatar!();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8)
                                .copyWith(bottom: hasReactions ? 16 : 0),
                            child: Avatar(
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
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                // TODO: issue shrinking the message based on width
                                maxWidth:
                                    !isImage ? double.infinity : Dimensions.mediaSizeMaxMessage,
                              ),
                              padding: EdgeInsets.only(
                                // make an image span the message width
                                left: removePadding ? 0 : 12,
                                // make an image span the message width
                                right: removePadding ? 0 : 12,
                                top: isImage && !showSender ? 0 : 8,
                                bottom: isImage ? 12 : 8,
                              ),
                              margin: EdgeInsets.only(
                                bottom: hasReactions ? 14 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: bubbleBorder,
                              ),
                              child: Flex(
                                direction: Axis.vertical,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: alignmentMessageText,
                                children: <Widget>[
                                  Visibility(
                                    visible: showSender,
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        bottom: 4,
                                        left: isImage ? 12 : 0,
                                        right: isImage ? 12 : 0,
                                      ), // make an image span the message width
                                      child: Text(
                                        displayName ?? formatSender(message.sender!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: isImage,
                                    maintainState: false,
                                    child: ClipRRect(
                                      borderRadius: showSender
                                          ? BorderRadius.zero
                                          : BorderRadius.only(
                                              topLeft: bubbleBorder.topLeft,
                                              topRight: bubbleBorder.topRight,
                                            ),
                                      child: MatrixImage(
                                        mxcUri: message.url,
                                        thumbnail: false,
                                        autodownload: StoreProvider.of<AppState>(context)
                                            .state
                                            .settingsStore
                                            .autoDownloadEnabled,
                                        fit: BoxFit.cover,
                                        rebuild: true,
                                        width: Dimensions.mediaSizeMaxMessage,
                                        height: Dimensions.mediaSizeMaxMessage,
                                        fallbackColor: Colors.transparent,
                                        loadingPadding: 32,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(
                                      bottom: 6,
                                      top: isImage ? 8 : 0,
                                      left: isImage ? 12 : 0,
                                      right: isImage ? 12 : 0,
                                    ),
                                    child: AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 150),
                                      crossFadeState: isEditing && selected
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      firstChild: MarkdownBody(
                                        data: body.trim(),
                                        onTapLink: (text, href, title) =>
                                            onConfirmLink(context, href),
                                        styleSheet: MarkdownStyleSheet(
                                          blockquote: TextStyle(
                                            backgroundColor: bubbleColor,
                                          ),
                                          blockquoteDecoration: BoxDecoration(
                                            color: replyColor,
                                            borderRadius: const BorderRadius.only(
                                              //TODO: shape similar to bubbleBorder
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                              bottomLeft: Radius.circular(4),
                                              bottomRight: Radius.circular(4),
                                            ),
                                          ),
                                          p: TextStyle(
                                            color: textColor,
                                            fontStyle: fontStyle,
                                            fontWeight: FontWeight.w300,
                                            fontSize:
                                                Theme.of(context).textTheme.subtitle2!.fontSize,
                                          ),
                                        ),
                                      ),
                                      secondChild: Padding(
                                        padding: EdgeInsets.only(left: 12, right: 12),
                                        child: IntrinsicWidth(
                                          child: TextFieldInline(
                                            body: body,
                                            onEdit: (text) => onSendEdit!(text, message),
                                          ),
                                        ),
                                      )
                                  ,)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: removePadding ? 12 : 0,
                                    ),
                                    child: Flex(
                                      /// *** Message Status Row ***
                                      direction: Axis.horizontal,
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: alignmentMessageText,
                                      children: [
                                        Visibility(
                                          visible:
                                              !isUserSent && message.type == EventTypes.encrypted,
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
                                        Visibility(
                                          visible: showStatus,
                                          child: Container(
                                            // timestamp and error message
                                            margin: EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textColor,
                                                fontWeight: FontWeight.w100,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible:
                                              isUserSent && message.type == EventTypes.encrypted,
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
                                                  strokeWidth: Dimensions.strokeWidthThin,
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: !message.pending,
                                              child: Container(
                                                width: Dimensions.indicatorSize,
                                                height: Dimensions.indicatorSize,
                                                margin: EdgeInsets.only(left: 4),
                                                decoration: ShapeDecoration(
                                                  color: indicatorColor,
                                                  shape: CircleBorder(
                                                    side: BorderSide(
                                                      color: indicatorIconColor!,
                                                      width: isRead ? 1.5 : 1,
                                                    ),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color: indicatorIconColor,
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: !message.syncing,
                                              child: Container(
                                                width: Dimensions.indicatorSize,
                                                height: Dimensions.indicatorSize,
                                                margin: EdgeInsets.only(left: 11),
                                                decoration: ShapeDecoration(
                                                  color: indicatorColor,
                                                  shape: CircleBorder(
                                                    side: BorderSide(
                                                      color: indicatorIconColor,
                                                      width: isRead ? 1.5 : 1,
                                                    ),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color: indicatorIconColor,
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: selected,
                              child: Positioned(
                                left: isUserSent ? 0 : null,
                                right: !isUserSent ? 0 : null,
                                bottom: 0,
                                child: Container(
                                  height: Dimensions.iconSize,
                                  transform: Matrix4.translationValues(0.0, 4.0, 0.0),
                                  child: buildReactionsInput(
                                    context,
                                    alignmentReaction,
                                    isUserSent,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: hasReactions && !selected,
                              child: Positioned(
                                left: isUserSent ? 0 : null,
                                right: !isUserSent ? 0 : null,
                                bottom: 0,
                                child: Container(
                                  height: Dimensions.iconSize,
                                  transform: Matrix4.translationValues(0.0, 4.0, 0.0),
                                  child: buildReactions(
                                    context,
                                    alignmentReaction,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

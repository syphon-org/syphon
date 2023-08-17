import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/room/selectors.dart';
import 'package:syphon/domain/settings/chat-settings/selectors.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/libraries/matrix/events/types.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class HomeChatListItem extends HookWidget {
  const HomeChatListItem({
    super.key,
    this.room = const Room(id: ''),
    this.messages = const <Message>[],
    this.messageLatest,
    this.selectedChats = const <String>[],
    this.roomTypeBadgesEnabled = true,
    this.onSelectChat,
    this.onToggleChatOptions,
  });

  final Room room;
  final List<Message> messages;
  final Message? messageLatest;
  final List<String> selectedChats;

  final bool roomTypeBadgesEnabled;

  final Function? onSelectChat;
  final Function? onToggleChatOptions;

  @override
  Widget build(BuildContext context) {
    final preview = formatPreview(room: room, message: messageLatest);
    final currentUser = useSelector<AppState, User>((state) => state.authStore.user, const User());

    final chatName = room.name ?? '';
    final newMessage = messageLatest != null &&
        room.lastRead < messageLatest!.timestamp &&
        messageLatest!.sender != currentUser.userId;

    var backgroundColor;
    var textStyle = const TextStyle();

    final chatColor = useSelector<AppState, Color>(
      (state) => selectChatColor(state, room.id),
      AppColors.hashedColor(room.id),
    );

    // highlight selected rooms if necessary
    if (selectedChats.isNotEmpty) {
      if (!selectedChats.contains(room.id)) {
        backgroundColor = Theme.of(context).scaffoldBackgroundColor;
      } else {
        backgroundColor = Theme.of(context).primaryColor.withAlpha(128);
      }
    }

    // show draft inidicator if it's an empty room
    if (room.drafting || messages.isEmpty) {
      textStyle = const TextStyle(fontStyle: FontStyle.italic);
    }

    if (messages.isNotEmpty && messageLatest != null) {
      // it has undecrypted message contained within
      if (messageLatest!.type == EventTypes.encrypted && messageLatest!.body!.isEmpty) {
        textStyle = const TextStyle(fontStyle: FontStyle.italic);
      }

      if (messageLatest!.body == null || messageLatest!.body!.isEmpty) {
        textStyle = const TextStyle(fontStyle: FontStyle.italic);
      }

      // display message as being 'unread'
      if (newMessage) {
        textStyle = textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyLarge!.color,
          fontWeight: FontWeight.w500,
        );
      }
    }

    // GestureDetector w/ animation
    return InkWell(
      onTap: () => onSelectChat?.call(room, chatName),
      onLongPress: () => onToggleChatOptions?.call(room: room),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor, // if selected, color seperately
        ),
        padding: EdgeInsets.symmetric(
          vertical: Theme.of(context).textTheme.titleMedium!.fontSize!,
        ).add(Dimensions.appPaddingHorizontal),
        child: Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  Avatar(
                    uri: room.avatarUri,
                    size: Dimensions.avatarSizeMin,
                    alt: formatRoomInitials(room: room),
                    background: chatColor,
                  ),
                  Visibility(
                    visible: !room.encryptionEnabled,
                    child: Positioned(
                      bottom: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.badgeAvatarSize,
                        ),
                        child: Container(
                          width: Dimensions.badgeAvatarSize,
                          height: Dimensions.badgeAvatarSize,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Icon(
                            Icons.lock_open,
                            color: Theme.of(context).iconTheme.color,
                            size: Dimensions.iconSizeMini,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: roomTypeBadgesEnabled && room.invite,
                    child: Positioned(
                      bottom: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: Dimensions.badgeAvatarSize,
                          height: Dimensions.badgeAvatarSize,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Icon(
                            Icons.mail_outline,
                            color: Theme.of(context).iconTheme.color,
                            size: Dimensions.iconSizeMini,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: newMessage,
                    child: Positioned(
                      top: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: Dimensions.badgeAvatarSizeSmall,
                          height: Dimensions.badgeAvatarSizeSmall,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: roomTypeBadgesEnabled && room.type == 'group' && !room.invite,
                    child: Positioned(
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: Dimensions.badgeAvatarSize,
                          height: Dimensions.badgeAvatarSize,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Icon(
                            Icons.group,
                            color: Theme.of(context).iconTheme.color,
                            size: Dimensions.badgeAvatarSizeSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: roomTypeBadgesEnabled && room.type == 'public' && !room.invite,
                    child: Positioned(
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: Dimensions.badgeAvatarSize,
                          height: Dimensions.badgeAvatarSize,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Icon(
                            Icons.public,
                            color: Theme.of(context).iconTheme.color,
                            size: Dimensions.badgeAvatarSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          chatName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        formatTimestamp(lastUpdateMillis: room.lastUpdate),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
                      ),
                    ],
                  ),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.merge(
                          textStyle,
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

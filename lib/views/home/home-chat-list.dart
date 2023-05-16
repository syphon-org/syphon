import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/selectors.dart';
import 'package:syphon/domain/hooks.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/room/selectors.dart';
import 'package:syphon/domain/rooms/selectors.dart';
import 'package:syphon/domain/settings/chat-settings/selectors.dart';
import 'package:syphon/domain/sync/selectors.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class HomeChatList extends HookWidget {
  const HomeChatList({
    super.key,
    this.searching = false,
    this.searchText = '',
    this.selectedChats = const [],
    this.onSelectChat,
    this.onToggleChatOptions,
  });

  final bool searching;
  final String searchText;
  final List<String> selectedChats;

  final Function? onSelectChat;
  final Function? onToggleChatOptions;

  @override
  Widget build(BuildContext context) {
    final store = useStore<AppState>();

    final chats = useSelector<AppState, List<Chat>>(selectHomeChats) ?? [];
    final syncing = useSelector<AppState, bool>(selectSyncingStatus) ?? false;

    final currentUser = useSelector<AppState, User>((state) => state.authStore.user);
    final roomTypeBadgesEnabled = useSelector<AppState, bool>(
          (state) => store.state.settingsStore.roomTypeBadgesEnabled,
        ) ??
        true;

    final messagesAll = useSelector<AppState, Map<String, List<Message>>>(
          (state) => state.eventStore.messages,
        ) ??
        {};
    final decryptedAll = useSelector<AppState, Map<String, List<Message>>>(
          (state) => state.eventStore.messagesDecrypted,
        ) ??
        {};
    final searchMessages = useSelector<AppState, List<Message>>(
          (state) => state.searchStore.searchMessages,
        ) ??
        [];

    final latestMessageAll = useMemoized<Map<String, Message?>>(() {
      return Map.fromIterable(
        chats,
        key: (chat) => chat.id,
        value: (chat) {
          final messages = messagesAll[chat.id] ?? const [];
          final decrypted = decryptedAll[chat.id] ?? const [];
          return latestMessage(messages, room: chat, decrypted: decrypted);
        },
      );
    }, [chats, messagesAll, decryptedAll]);

    final noChatsLabel = syncing ? Strings.labelSyncingChats : Strings.labelMessagesEmpty;
    final noSearchResults = searching && searchMessages.isEmpty && searchText.isNotEmpty;

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              constraints: BoxConstraints(
                minWidth: Dimensions.mediaSizeMin,
                maxWidth: Dimensions.mediaSizeMax,
                maxHeight: Dimensions.mediaSizeMin,
              ),
              child: SvgPicture.asset(
                Assets.heroChatNotFound,
                semanticsLabel: Strings.semanticsHomeDefault,
              ),
            ),
            GestureDetector(
              child: Container(
                margin: EdgeInsets.only(bottom: 48),
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  noChatsLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: noSearchResults ? 0 : chats.length,
      itemBuilder: (BuildContext context, int index) {
        final room = chats[index];
        final messages = messagesAll[room.id] ?? const [];
        final messageLatest = latestMessageAll[room.id];

        final preview = formatPreview(room: room, message: messageLatest);
        final chatName = room.name ?? '';
        final newMessage = messageLatest != null &&
            room.lastRead < messageLatest.timestamp &&
            messageLatest.sender != currentUser?.userId;

        var backgroundColor;
        var textStyle = TextStyle();
        final chatColor = selectChatColor(store, room.id);

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
          textStyle = TextStyle(fontStyle: FontStyle.italic);
        }

        if (messages.isNotEmpty && messageLatest != null) {
          // it has undecrypted message contained within
          if (messageLatest.type == EventTypes.encrypted && messageLatest.body!.isEmpty) {
            textStyle = TextStyle(fontStyle: FontStyle.italic);
          }

          if (messageLatest.body == null || messageLatest.body!.isEmpty) {
            textStyle = TextStyle(fontStyle: FontStyle.italic);
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
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
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
      },
    );
  }
}

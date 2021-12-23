import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/selectors.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/chat-settings/selectors.dart';
import 'package:syphon/store/settings/models.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:syphon/views/widgets/messages/message.dart';
import 'package:syphon/views/widgets/messages/typing-indicator.dart';

class MessageList extends StatefulWidget {
  final String? roomId;

  final bool editing;
  final bool showAvatars;
  final Message? selectedMessage;
  final TextEditingController editorController;

  final ScrollController scrollController;

  final Function? onSendEdit;
  final Function? onSelectReply;
  final void Function({Message? message, User? user, String? userId})? onViewUserDetails;
  final void Function(Message?)? onToggleSelectedMessage;

  const MessageList({
    Key? key,
    required this.roomId,
    required this.scrollController,
    required this.editorController,
    this.showAvatars = true,
    this.editing = false,
    this.selectedMessage,
    this.onSendEdit,
    this.onSelectReply,
    this.onViewUserDetails,
    this.onToggleSelectedMessage,
  }) : super(key: key);

  @override
  MessageListState createState() => MessageListState();
}

class MessageListState extends State<MessageList> with Lifecycle<MessageList> {
  final TextEditingController controller = TextEditingController();

  final Map<String, Color> colorMap = {};
  final Map<String, double> luminanceMap = {};

  @override
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    final messages = roomMessages(store.state, widget.roomId);

    setState(() {
      for (final message in messages) {
        final userColor = Colours.hashedColor(message.sender);
        colorMap[message.sender ?? ''] = userColor;
        luminanceMap[message.sender ?? ''] = userColor.computeLuminance();
      }
    });
  }

  onSelectReply(Message? message) {
    final store = StoreProvider.of<AppState>(context);
    final roomId = widget.roomId;

    try {
      store.dispatch(selectReply(roomId: roomId, message: message));
    } catch (error) {
      printError(error.toString());
    }
  }

  onToggleReaction({Message? message, String? emoji}) {
    final store = StoreProvider.of<AppState>(context);
    final roomId = widget.roomId;
    final room = selectRoom(id: roomId, state: store.state);

    store.dispatch(
      toggleReaction(room: room, message: message, emoji: emoji),
    );
  }

  onInputReaction({Message? message, _Props? props}) async {
    final height = MediaQuery.of(context).size.height;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: height / 2.2,
        padding: EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: EmojiPicker(
            config: Config(
              columns: 9,
              emojiSizeMax: 24,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              bgColor: Theme.of(context).scaffoldBackgroundColor,
              categoryIcons: CategoryIcons(
                smileyIcon: Icons.tag_faces_rounded,
                objectIcon: Icons.lightbulb,
                travelIcon: Icons.flight,
                activityIcon: Icons.sports_soccer,
                symbolIcon: Icons.tag,
              ),
            ),
            onEmojiSelected: (category, emoji) {
              onToggleReaction(
                emoji: emoji.emoji,
                message: message,
              );

              Navigator.pop(context, false);
              widget.onToggleSelectedMessage!(null);
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store, widget.roomId),
        builder: (context, props) {
          final lockScrolling = widget.selectedMessage != null && !widget.editing;
          return GestureDetector(
            onTap: () => widget.onToggleSelectedMessage!(null),
            child: ListView(
              reverse: true,
              padding: EdgeInsets.only(bottom: 16),
              physics: lockScrolling ? const NeverScrollableScrollPhysics() : null,
              controller: widget.scrollController,
              children: [
                TypingIndicator(
                  roomUsers: props.users,
                  typing: props.room.userTyping,
                  usersTyping: props.room.usersTyping,
                  selectedMessageId:
                      widget.selectedMessage != null ? widget.selectedMessage!.id : null,
                ),
                ListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  // TODO: add padding based on widget height to allow
                  // TODO: user to always pull down to load regardless of list size
                  padding: EdgeInsets.only(bottom: 0, top: props.messages.length < 10 ? 200 : 0),
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: true,
                  itemCount: props.messages.length,
                  scrollDirection: Axis.vertical,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final message = props.messages[index];
                    final lastMessage = index != 0 ? props.messages[index - 1] : null;
                    final nextMessage =
                        index + 1 < props.messages.length ? props.messages[index + 1] : null;

                    // was sent at least 2 minutes after the previous message
                    final isNewContext =
                        ((lastMessage?.timestamp ?? 0) - message.timestamp) > 120000;

                    final isLastSender =
                        lastMessage != null && lastMessage.sender == message.sender;
                    final isNextSender =
                        nextMessage != null && nextMessage.sender == message.sender;
                    final isUserSent = props.currentUser.userId == message.sender;

                    final selectedMessageId =
                        widget.selectedMessage != null ? widget.selectedMessage!.id : null;

                    final user = props.users[message.sender];
                    final avatarUri = user?.avatarUri;
                    final displayName = user?.displayName;
                    final color = colorMap[message.sender];
                    final luminance = luminanceMap[message.sender];

                    return MessageWidget(
                      key: Key(message.id ?? ''),
                      message: message,
                      editorController: widget.editorController,
                      isEditing: widget.editing,
                      isUserSent: isUserSent,
                      isLastSender: isLastSender,
                      isNextSender: isNextSender,
                      isNewContext: isNewContext,
                      messageOnly: !isUserSent && !widget.showAvatars,
                      lastRead: props.room.lastRead,
                      selectedMessageId: selectedMessageId,
                      avatarUri: avatarUri,
                      displayName: displayName,
                      themeType: props.themeType,
                      color: props.chatColorPrimary ?? color,
                      luminance: luminance,
                      timeFormat: props.timeFormat,
                      onSendEdit: widget.onSendEdit,
                      onSwipe: onSelectReply,
                      onPressAvatar: () => widget.onViewUserDetails!(
                        message: message,
                        user: user,
                        userId: message.sender,
                      ),
                      onLongPress: (msg) => widget.onToggleSelectedMessage!(msg),
                      onInputReaction: () => onInputReaction(
                        message: message,
                        props: props,
                      ),
                      onToggleReaction: (emoji) => onToggleReaction(
                        emoji: emoji,
                        message: message,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final Room room;
  final User currentUser;
  final ThemeType themeType;
  final TimeFormat timeFormat;
  final Map<String, User> users;
  final List<Message> messages;
  final List<Message> messagesRaw;
  final Color? chatColorPrimary;

  const _Props({
    required this.room,
    required this.themeType,
    required this.users,
    required this.messages,
    required this.messagesRaw,
    required this.currentUser,
    required this.timeFormat,
    required this.chatColorPrimary,
  });

  @override
  List<Object> get props => [
        room,
        users,
        messagesRaw,
      ];

  static _Props mapStateToProps(Store<AppState> store, String? roomId) => _Props(
        timeFormat:
            store.state.settingsStore.timeFormat24Enabled ? TimeFormat.hr24 : TimeFormat.hr12,
        themeType: store.state.settingsStore.themeSettings.themeType,
        currentUser: store.state.authStore.user,
        chatColorPrimary: selectBubbleColor(store, roomId),
        room: selectRoom(id: roomId, state: store.state),
        users: messageUsers(roomId: roomId, state: store.state),
        messagesRaw: roomMessages(store.state, roomId),
        messages: latestMessages(
          filterMessages(
            combineOutbox(
              outbox: roomOutbox(store.state, roomId),
              messages: roomMessages(store.state, roomId),
            ),
            store.state,
          ),
        ),
      );
}

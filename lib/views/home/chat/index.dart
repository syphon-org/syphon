import 'dart:async';
import 'dart:io';

// Store
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/store/rooms/room/selectors.dart';
import 'package:Tether/views/home/chat/details-message.dart';
import 'package:Tether/views/home/chat/details-chat.dart';
import 'package:Tether/views/widgets/image-matrix.dart';
import 'package:Tether/views/widgets/message-typing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:redux/redux.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/events/selectors.dart';
import 'package:Tether/store/rooms/selectors.dart' as roomSelectors;
import 'package:Tether/store/rooms/events/actions.dart';

// Global widgets
import 'package:Tether/views/widgets/message.dart';

// Styling
import 'package:Tether/global/colors.dart';
import 'package:Tether/views/widgets/menu.dart';

/**
 * Resources:
 * https://stackoverflow.com/questions/45900387/multi-line-textfield-in-flutter
 * https://stackoverflow.com/questions/50400529/how-to-update-flutter-textfields-height-and-width
 * https://stackoverflow.com/questions/55863766/how-to-prevent-keyboard-from-dismissing-on-pressing-submit-key-in-flutter
 * https://medium.com/nonstopio/make-the-list-auto-scrollable-when-you-add-the-new-message-in-chat-messages-functionality-in-19e457a838a7
 * 
 */
enum ChatOptions {
  search,
  allMedia,
  chatSettings,
  inviteFriends,
  muteNotifications
}

class ChatViewArguements {
  final String roomId;
  final String title;

  // Improve loading times
  ChatViewArguements({
    this.roomId,
    this.title,
  });
}

class ChatView extends StatefulWidget {
  const ChatView({Key key}) : super(key: key);

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  Timer typingNotifier;
  Timer typingNotifierTimeout;
  FocusNode inputFieldNode;
  Map<String, Color> senderColors;
  bool sendable = false;
  Message selectedMessage;
  final editorController = TextEditingController();
  final messagesController = ScrollController();

  @override
  void initState() {
    super.initState();
    inputFieldNode = FocusNode();
    inputFieldNode.addListener(() {
      if (!inputFieldNode.hasFocus && this.typingNotifier != null) {
        this.typingNotifier.cancel();
        this.setState(() {
          typingNotifier = null;
        });
      }
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final arguements =
        ModalRoute.of(context).settings.arguments as ChatViewArguements;

    final room = store.state.roomStore.rooms[arguements.roomId];

    final draft = room.draft;
    if (draft != null && draft.type == MessageTypes.TEXT) {
      final text = draft.body;
      this.setState(() {
        sendable = text != null && text.isNotEmpty;
      });

      editorController.value = TextEditingValue(
        text: text,
        selection: TextSelection.fromPosition(
          TextPosition(
            offset: text.length,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    inputFieldNode.dispose();
    super.dispose();
    if (this.typingNotifier != null) {
      this.typingNotifier.cancel();
    }

    if (this.typingNotifierTimeout != null) {
      this.typingNotifierTimeout.cancel();
    }
  }

  @protected
  onUpdateMessage(String text, _Props props) {
    this.setState(() {
      sendable = text != null && text.isNotEmpty;
    });

    // start an interval for updating typing status
    if (inputFieldNode.hasFocus && this.typingNotifier == null) {
      props.onSendTyping(typing: true, roomId: props.room.id);
      this.setState(() {
        typingNotifier = Timer.periodic(
          Duration(milliseconds: 4000),
          (timer) => props.onSendTyping(typing: true, roomId: props.room.id),
        );
      });
    }

    // Handle a timeout of the interval if the user idles with input focused
    if (inputFieldNode.hasFocus) {
      if (typingNotifierTimeout != null) {
        this.typingNotifierTimeout.cancel();
      }
      this.setState(() {
        typingNotifierTimeout = Timer(Duration(milliseconds: 4000), () {
          if (typingNotifier != null) {
            this.typingNotifier.cancel();
            this.setState(() {
              typingNotifier = null;
              typingNotifierTimeout = null;
            });
            // run after to avoid flickering
            props.onSendTyping(typing: false, roomId: props.room.id);
          }
        });
      });
    }
  }

  @protected
  onToggleMessageOptions({Message message}) {
    this.setState(() {
      selectedMessage = message;
    });
  }

  onDismissMessageOptions() {
    this.setState(() {
      selectedMessage = null;
    });
  }

  Widget buildMessageList(
    BuildContext context,
    _Props props,
  ) {
    final messages = props.messages;

    return GestureDetector(
      onTap: onDismissMessageOptions,
      child: Container(
        child: ListView(
          reverse: true,
          physics: selectedMessage != null
              ? const NeverScrollableScrollPhysics()
              : null,
          children: [
            Visibility(
              visible: props.room.userTyping,
              child: MessageTypingWidget(
                theme: props.theme,
                lastRead: props.room.lastRead,
                selectedMessageId: this.selectedMessage != null
                    ? this.selectedMessage.id
                    : null,
              ),
            ),
            ListView.builder(
              reverse: true,
              shrinkWrap: true,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: true,
              itemCount: messages.length,
              padding: EdgeInsets.only(bottom: 8),
              scrollDirection: Axis.vertical,
              controller: messagesController,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                final message = messages[index];
                final lastMessage = index != 0 ? messages[index - 1] : null;
                final nextMessage =
                    index + 1 < messages.length ? messages[index + 1] : null;

                final isLastSender =
                    lastMessage != null && lastMessage.sender == message.sender;
                final isNextSender =
                    nextMessage != null && nextMessage.sender == message.sender;
                final isUserSent = props.userId == message.sender;
                final selectedMessageId = this.selectedMessage != null
                    ? this.selectedMessage.id
                    : null;

                final avatarUri = props.room.users[message.sender]?.avatarUri;
                return MessageWidget(
                  message: message,
                  isUserSent: isUserSent,
                  isLastSender: isLastSender,
                  isNextSender: isNextSender,
                  lastRead: props.room.lastRead,
                  selectedMessageId: selectedMessageId,
                  onLongPress: onToggleMessageOptions,
                  avatarUri: avatarUri,
                  theme: props.theme,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /**
     * TODO: Room Drafts
     */
  // if (props.room.isDraftRoom) {
  //   final convertedRoomId = await props.onConvertDraftRoom();
  //   final arguements =
  //       ModalRoute.of(context).settings.arguments as ChatViewArguements;
  //   Navigator.of(context).pushReplacementNamed(
  //     '/home/chat',
  //     arguments: ChatViewArguements(
  //       roomId: convertedRoomId.id,
  //       title: arguements.title,
  //     ),
  //   );
  // }
  @protected
  onSubmitMessage(_Props props) async {
    print(editorController.text);
    props.onSendMessage(
      body: editorController.text,
      type: MessageTypes.TEXT,
    );
    editorController.clear();
    FocusScope.of(context).unfocus();
  }

  Widget buildChatInput(
    BuildContext context,
    _Props props,
  ) {
    double width = MediaQuery.of(context).size.width;
    double messageInputWidth = width - 72;

    Color inputTextColor = const Color(BASICALLY_BLACK);
    Color inputColorBackground = const Color(ENABLED_GREY);
    Color inputCursorColor = Colors.blueGrey;
    Color sendButtonColor = const Color(DISABLED_GREY);

    if (sendable) {
      sendButtonColor = Theme.of(context).primaryColor;
    }

    if (Theme.of(context).brightness == Brightness.dark) {
      inputTextColor = Colors.white;
      inputColorBackground = Colors.blueGrey;
      inputCursorColor = Colors.white;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(
            maxWidth: messageInputWidth,
          ),
          child: TextField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            cursorColor: inputCursorColor,
            focusNode: inputFieldNode,
            controller: editorController,
            onChanged: (text) => onUpdateMessage(text, props),
            onSubmitted:
                !sendable ? null : (text) => this.onSubmitMessage(props),
            style: TextStyle(
              height: 1.5,
              color: inputTextColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputColorBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              hintText: 'Matrix message (unencrypted)',
            ),
          ),
        ),
        Container(
          width: 48.0,
          padding: EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: !sendable ? null : () => this.onSubmitMessage(props),
            child: CircleAvatar(
              backgroundColor: sendButtonColor,
              child: Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @protected
  buildRoomAppBar({
    _Props props,
    BuildContext context,
  }) {
    return AppBar(
      brightness: Brightness.dark, // TOOD: this should inherit from theme
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (editorController.text != null &&
                    0 < editorController.text.length)
                  props.onSaveDraftMessage(
                    body: editorController.text,
                    type: MessageTypes.TEXT,
                  );
                Navigator.pop(context, false);
              },
            ),
          ),
          GestureDetector(
            child: Hero(
              tag: "ChatAvatar",
              child: Container(
                padding: EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: props.room.avatarUri != null
                      ? Colors.transparent
                      : props.roomPrimaryColor,
                  child: props.room.avatarUri != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimensions.thumbnailSizeMax,
                          ),
                          child: MatrixImage(
                            width: 52,
                            height: 52,
                            mxcUri: props.room.avatarUri,
                          ),
                        )
                      : Text(
                          formatRoomInitials(room: props.room),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/home/chat/settings',
                arguments: ChatSettingsArguments(
                  roomId: props.room.id,
                  title: props.room.name,
                ),
              );
            },
          ),
          Text(
            props.room.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w100,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        RoundedPopupMenu<ChatOptions>(
          onSelected: (ChatOptions result) {
            switch (result) {
              case ChatOptions.chatSettings:
                return Navigator.pushNamed(
                  context,
                  '/home/chat/settings',
                  arguments: ChatSettingsArguments(
                    roomId: props.room.id,
                    title: props.room.name,
                  ),
                );
              default:
                break;
            }
          },
          icon: Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ChatOptions>>[
            const PopupMenuItem<ChatOptions>(
              value: ChatOptions.search,
              child: Text('Search'),
            ),
            const PopupMenuItem<ChatOptions>(
              value: ChatOptions.allMedia,
              child: Text('All Media'),
            ),
            const PopupMenuItem<ChatOptions>(
              value: ChatOptions.chatSettings,
              child: Text('Chat Settings'),
            ),
            const PopupMenuItem<ChatOptions>(
              value: ChatOptions.inviteFriends,
              child: Text('Invite Friends'),
            ),
            const PopupMenuItem<ChatOptions>(
              value: ChatOptions.muteNotifications,
              child: Text('Mute Notifications'),
            ),
          ],
        )
      ],
    );
  }

  @protected
  buildMessageOptionsBar({
    _Props props,
    BuildContext context,
  }) {
    return AppBar(
      brightness: Brightness.dark, // TOOD: this should inherit from theme
      backgroundColor: Colors.grey[500],
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: onDismissMessageOptions,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.info),
          tooltip: 'Message Details',
          color: Colors.white,
          onPressed: () => {
            Navigator.pushNamed(
              context,
              '/home/chat/details',
              arguments: MessageDetailArguments(
                roomId: props.room.id,
                message: selectedMessage,
              ),
            ),
            this.setState(() {
              selectedMessage = null;
            })
          },
        ),
        IconButton(
            icon: Icon(Icons.delete),
            iconSize: 28.0,
            tooltip: 'Delete Message',
            color: Colors.white,
            onPressed: () {
              props.onDeleteMessage(
                message: this.selectedMessage,
              );
              this.setState(() {
                selectedMessage = null;
              });
            }),
        Visibility(
          visible: isTextMessage(message: selectedMessage),
          child: IconButton(
            icon: Icon(Icons.content_copy),
            iconSize: 22.0,
            tooltip: 'Copy Message Content',
            color: Colors.white,
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: selectedMessage.formattedBody ?? selectedMessage.body,
                ),
              );
              this.setState(() {
                selectedMessage = null;
              });
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.reply),
          iconSize: 28.0,
          tooltip: 'Quote and Reply',
          color: Colors.white,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.share),
          iconSize: 24.0,
          tooltip: 'Search Chats',
          color: Colors.white,
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(
          store,
          (ModalRoute.of(context).settings.arguments as ChatViewArguements)
              .roomId,
        ),
        builder: (context, props) {
          double height = MediaQuery.of(context).size.height;
          final closedInputPadding = !inputFieldNode.hasFocus &&
              Platform.isIOS &&
              Dimensions.buttonlessHeightiOS < height;

          final isScrolling =
              messagesController.hasClients && messagesController.offset != 0;

          Color inputContainerColor = Colors.white;

          if (Theme.of(context).brightness == Brightness.dark) {
            inputContainerColor = Colors.grey[850];
          }

          var currentAppBar = buildRoomAppBar(
            props: props,
            context: context,
          );

          if (this.selectedMessage != null) {
            currentAppBar = buildMessageOptionsBar(
              props: props,
              context: context,
            );
          }

          return Scaffold(
            appBar: currentAppBar,
            backgroundColor: selectedMessage != null
                ? Theme.of(context).scaffoldBackgroundColor.withAlpha(64)
                : Theme.of(context).scaffoldBackgroundColor,
            body: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: props.onForceFetchSync,
                      child: GestureDetector(
                        onTap: () {
                          // Disimiss keyboard if they click outside the text input
                          inputFieldNode.unfocus();
                          FocusScope.of(context).unfocus();
                        },
                        child: Stack(
                          children: [
                            buildMessageList(
                              context,
                              props,
                            ),
                            Positioned(
                              child: Visibility(
                                visible: props.roomsLoading,
                                child: Container(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    RefreshProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                        PRIMARY_COLOR,
                                      ),
                                      value: null,
                                    ),
                                  ],
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      top: 12,
                      left: 8,
                      right: 8,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: inputContainerColor,
                      boxShadow: isScrolling
                          ? [
                              BoxShadow(
                                  blurRadius: 6,
                                  offset: Offset(0, -4),
                                  color: Colors.black12)
                            ]
                          : [],
                    ),
                    child: AnimatedPadding(
                      duration: Duration(
                          milliseconds: inputFieldNode.hasFocus ? 225 : 0),
                      padding: EdgeInsets.only(
                        bottom: closedInputPadding ? 16 : 0,
                      ),
                      child: buildChatInput(
                        context,
                        props,
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

class _Props extends Equatable {
  final Room room;
  final String userId;
  final List<Message> messages;
  final bool roomsLoading;
  final ThemeType theme;
  final Color roomPrimaryColor;

  final Function onSendTyping;
  final Function onSendMessage;
  final Function onDeleteMessage;
  final Function onSaveDraftMessage;
  final Function onForceFetchSync;

  _Props({
    @required this.room,
    @required this.theme,
    @required this.userId,
    @required this.messages,
    @required this.roomsLoading,
    @required this.roomPrimaryColor,
    @required this.onSendTyping,
    @required this.onSendMessage,
    @required this.onDeleteMessage,
    @required this.onSaveDraftMessage,
    @required this.onForceFetchSync,
  });

  static _Props mapStoreToProps(Store<AppState> store, String roomId) => _Props(
        userId: store.state.userStore.user.userId,
        theme: store.state.settingsStore.theme,
        roomsLoading: store.state.roomStore.loading,
        room: roomSelectors.room(
          id: roomId,
          state: store.state,
        ),
        messages: latestMessages(
          wrapOutboxMessages(
            messages:
                roomSelectors.room(id: roomId, state: store.state).messages,
            outbox: roomSelectors.room(id: roomId, state: store.state).outbox,
          ),
        ),
        roomPrimaryColor: () {
          final customChatSettings =
              store.state.settingsStore.customChatSettings ?? Map();

          if (customChatSettings[roomId] != null) {
            return Color(customChatSettings[roomId].primaryColor);
          }

          return Colors.grey;
        }(),
        onForceFetchSync: () async {
          await store.dispatch(fetchSync());
          return Future(() => true);
        },
        onSaveDraftMessage: ({
          String body,
          String type,
        }) {
          store.dispatch(saveDraft(
            body: body,
            type: type,
            room: store.state.roomStore.rooms[roomId],
          ));
        },
        onSendMessage: ({
          String body,
          String type,
        }) async {
          store.dispatch(sendMessage(
            body: body,
            room: store.state.roomStore.rooms[roomId],
            type: type,
          ));
        },
        onDeleteMessage: ({
          Message message,
        }) {
          if (message != null) {
            store.dispatch(deleteMessage(message: message));
          }
        },
        onSendTyping: ({typing, roomId}) => store.dispatch(
          sendTyping(
            typing: typing,
            roomId: roomId,
          ),
        ),
        /**
         * TODO: Room Drafts
         */
        // onConvertDraftRoom: () async {
        //   final room = store.state.roomStore.rooms[roomId];
        //   return store.dispatch(convertDraftRoom(room: room));
        // },
      );

  @override
  List<Object> get props => [
        userId,
        messages,
        room,
        roomPrimaryColor,
        roomsLoading,
      ];
}

import 'dart:async';
import 'dart:io';

// Store
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/views/home/chat/chat-input.dart';
import 'package:syphon/views/home/chat/details-message.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/dialog-encryption.dart';
import 'package:syphon/views/home/chat/dialog-invite.dart';
import 'package:syphon/views/widgets/image-matrix.dart';
import 'package:syphon/views/widgets/message-typing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:redux/redux.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/events/selectors.dart';
import 'package:syphon/store/rooms/selectors.dart' as roomSelectors;
import 'package:syphon/store/rooms/events/actions.dart';

// Global widgets
import 'package:syphon/views/widgets/message.dart';

// Styling
import 'package:syphon/global/colors.dart';
import 'package:syphon/views/widgets/menu.dart';

enum ChatOptions {
  search,
  allMedia,
  chatSettings,
  inviteFriends,
  muteNotifications,
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

  double overshoot = 0;
  bool loadMore = false;
  String mediumType = MediumType.plaintext;
  String newMediumType = MediumType.plaintext;

  final editorController = TextEditingController();
  final messagesController = ScrollController();
  final listViewController = ScrollController();

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
  void onMounted() async {
    final arguements =
        ModalRoute.of(context).settings.arguments as ChatViewArguements;
    final store = StoreProvider.of<AppState>(context);
    final props = _Props.mapStoreToProps(store, arguements.roomId);
    final draft = props.room.draft;

    // TODO: remove after the cache is updated
    if (props.room.invite != null && props.room.invite) {
      showDialog(
        context: context,
        barrierDismissible: false,
        child: DialogInvite(
          onAccept: props.onAcceptInvite,
        ),
      );
    }
    if (props.room.encryptionEnabled) {
      this.setState(() {
        mediumType = MediumType.encryption;
      });
    }

    if (props.room.encryptionEnabled) {
      final usersDeviceKeys = await store.dispatch(
        fetchDeviceKeys(users: props.room.users),
      );

      store.dispatch(setDeviceKeys(usersDeviceKeys));
    }

    if (props.room.messages.length < 10) {
      props.onLoadFirstBatch();
    }

    messagesController.addListener(() {
      final extentBefore = messagesController.position.extentBefore;
      final max = messagesController.position.maxScrollExtent;

      final limit = max - extentBefore;
      final atLimit = Platform.isAndroid ? limit < 1 : limit < -32;

      if (atLimit && !loadMore) {
        this.setState(() {
          loadMore = true;
        });
        props.onLoadMoreMessages();
      } else if (!atLimit && loadMore && !props.loading) {
        this.setState(() {
          loadMore = false;
        });
      }
    });

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
    messagesController.dispose();
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
  onChangeMediumType({String newMediumType, _Props props}) {
    // noop
    if (mediumType == newMediumType) {
      return;
    }

    if (newMediumType == MediumType.encryption) {
      showDialog(
        context: context,
        barrierDismissible: false,
        child: DialogEncryption(
          onAccept: () {
            props.onToggleEncryption();

            setState(() {
              mediumType = newMediumType;
            });
          },
        ),
      );
    } else {
      // other mediums like sms, with no confirmation
      setState(() {
        mediumType = newMediumType;
      });
    }
  }

  @protected
  onToggleMessageOptions({Message message}) {
    this.setState(() {
      selectedMessage = message;
    });
  }

  @protected
  onDismissMessageOptions() {
    this.setState(() {
      selectedMessage = null;
    });
  }

  @protected
  onSubmitMessage(_Props props) async {
    props.onSendMessage(
      body: editorController.text,
      type: MessageTypes.TEXT,
    );
    editorController.clear();
    FocusScope.of(context).unfocus();
  }

  @protected
  onShowMediumMenu(context, props) async {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    showMenu(
      elevation: 4.0,
      context: context,
      position: RelativeRect.fromLTRB(
        width,
        // input height and padding
        height - Dimensions.inputSizeMin,
        0.0,
        0.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      items: [
        PopupMenuItem<String>(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              this.onChangeMediumType(
                newMediumType: MediumType.plaintext,
                props: props,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: const Color(DISABLED_GREY),
                      child: Stack(children: [
                        Positioned(
                          right: 0,
                          bottom: -1.5,
                          child: Icon(
                            Icons.lock_open,
                            size: Dimensions.miniLockSize,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.send,
                          size: Dimensions.iconSizeLite,
                          color: Colors.white,
                        ),
                      ]),
                    ),
                  ),
                  Text('Unencrypted'),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              this.onChangeMediumType(
                newMediumType: MediumType.encryption,
                props: props,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Stack(children: [
                        Positioned(
                          right: 0,
                          bottom: -1.5,
                          child: Icon(
                            Icons.lock,
                            size: Dimensions.miniLockSize,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.send,
                          size: Dimensions.iconSizeLite,
                          color: Colors.white,
                        ),
                      ]),
                    ),
                  ),
                  Text('Encrypted'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
          padding: EdgeInsets.only(bottom: 12),
          physics: selectedMessage != null
              ? const NeverScrollableScrollPhysics()
              : null,
          controller: messagesController,
          children: [
            MessageTypingWidget(
              typing: props.room.userTyping,
              usersTyping: props.room.usersTyping,
              roomUsers: props.room.users,
              selectedMessageId:
                  this.selectedMessage != null ? this.selectedMessage.id : null,
            ),
            ListView.builder(
              reverse: true,
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: 4),
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: true,
              itemCount: messages.length,
              scrollDirection: Axis.vertical,
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
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  Hero(
                      tag: "ChatAvatar",
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: props.roomPrimaryColor,
                        child: props.room.avatarUri != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.thumbnailSizeMax,
                                ),
                                child: MatrixImage(
                                  width: Dimensions.avatarSize,
                                  height: Dimensions.avatarSize,
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
                      )),
                  Visibility(
                    visible: props.room.encryptionEnabled,
                    child: Positioned(
                      bottom: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.thumbnailSizeMax,
                        ),
                        child: Container(
                          height: 16,
                          width: 16,
                          color: Colors.green,
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
        Visibility(
          maintainSize: false,
          visible: debug == 'true',
          child: IconButton(
            icon: Icon(Icons.gamepad),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: 'Debug Room Function',
            color: Colors.white,
            onPressed: () {
              props.onCheatCode();
            },
          ),
        ),
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
          tooltip: 'Share Chats',
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
            inputContainerColor = Theme.of(context).scaffoldBackgroundColor;
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
                              visible: props.loading,
                              child: Container(
                                  child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  RefreshProgressIndicator(
                                    strokeWidth: Dimensions.defaultStrokeWidth,
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
                  Container(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 12,
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
                      child: ChatInput(
                        sendable: sendable,
                        focusNode: inputFieldNode,
                        mediumType: mediumType,
                        controller: editorController,
                        onChangeMethod: () => onShowMediumMenu(context, props),
                        onChangeMessage: (text) => onUpdateMessage(text, props),
                        onSubmitMessage: () => this.onSubmitMessage(props),
                        onSubmittedMessage: (text) =>
                            this.onSubmitMessage(props),
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
  final bool loading;
  final ThemeType theme;
  final Color roomPrimaryColor;

  final Function onSendTyping;
  final Function onSendMessage;
  final Function onDeleteMessage;
  final Function onSaveDraftMessage;
  final Function onLoadMoreMessages;
  final Function onLoadFirstBatch;
  final Function onAcceptInvite;
  final Function onToggleEncryption;
  final Function onCheatCode;

  _Props({
    @required this.room,
    @required this.theme,
    @required this.userId,
    @required this.messages,
    @required this.loading,
    @required this.roomPrimaryColor,
    @required this.onSendTyping,
    @required this.onSendMessage,
    @required this.onDeleteMessage,
    @required this.onSaveDraftMessage,
    @required this.onLoadMoreMessages,
    @required this.onLoadFirstBatch,
    @required this.onAcceptInvite,
    @required this.onToggleEncryption,
    @required this.onCheatCode,
  });

  static _Props mapStoreToProps(Store<AppState> store, String roomId) => _Props(
      userId: store.state.authStore.user.userId,
      theme: store.state.settingsStore.theme,
      loading: (store.state.roomStore.rooms[roomId] ?? Room()).syncing,
      room: roomSelectors.room(
        id: roomId,
        state: store.state,
      ),
      messages: latestMessages(
        wrapOutboxMessages(
          messages: roomSelectors.room(id: roomId, state: store.state).messages,
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
        final room = store.state.roomStore.rooms[roomId];
        if (room.encryptionEnabled) {
          return store.dispatch(sendMessageEncrypted(
            body: body,
            room: room,
            type: type,
          ));
        }

        return store.dispatch(sendMessage(
          body: body,
          room: room,
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
      onAcceptInvite: () {
        store.dispatch(acceptRoom(
          room: Room(id: roomId),
        ));
      },
      onSendTyping: ({typing, roomId}) => store.dispatch(
            sendTyping(
              typing: typing,
              roomId: roomId,
            ),
          ),
      onLoadFirstBatch: () {
        final room = store.state.roomStore.rooms[roomId] ?? Room();
        store.dispatch(
          fetchMessageEvents(
            room: room,
          ),
        );
      },
      onToggleEncryption: () {
        final room = store.state.roomStore.rooms[roomId] ?? Room();
        store.dispatch(
          toggleRoomEncryption(room: room),
        );
      },
      onLoadMoreMessages: () {
        final room = store.state.roomStore.rooms[roomId] ?? Room();
        store.dispatch(fetchMessageEvents(
          room: room,
          startHash: room.endHash,
        ));
      },
      onCheatCode: () {
        final room = store.state.roomStore.rooms[roomId] ?? Room();
      });

  @override
  List<Object> get props => [
        userId,
        messages,
        room,
        roomPrimaryColor,
        loading,
      ];
}

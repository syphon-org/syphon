import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/events/selectors.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/media/filters.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/chat-settings/selectors.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/media-preview-screen.dart';
import 'package:syphon/views/home/chat/widgets/chat-input.dart';
import 'package:syphon/views/home/chat/widgets/dialog-encryption.dart';
import 'package:syphon/views/home/chat/widgets/dialog-invite.dart';
import 'package:syphon/views/home/chat/widgets/message-list.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-chat.dart';
import 'package:syphon/views/widgets/appbars/appbar-options-message.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class ChatScreenArguments {
  final String? roomId;
  final String? title;

  // Improve loading times
  ChatScreenArguments({this.roomId, this.title});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  bool sending = false;
  bool loadMore = false;
  bool editing = false;

  Message? selectedMessage;
  Map<String, Color>? senderColors;

  String? mediumType = MediumType.plaintext;

  final inputFieldNode = FocusNode();
  final inputController = TextEditingController();
  final editorController = TextEditingController();
  final messagesController = ScrollController();
  final listViewController = ScrollController();

  @override
  void dispose() {
    inputFieldNode.dispose();
    messagesController.dispose();
    super.dispose();
  }

  onMounted(_Props props) async {
    final draft = props.room.draft;

    // only marked if read receipts are enabled
    props.onMarkRead();

    if (props.room.invite) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DialogInvite(
          onAccept: props.onAcceptInvite,
          onReject: () {
            props.onRejectInvite();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          onCancel: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      );
    }

    if (props.room.encryptionEnabled) {
      props.onUpdateDeviceKeys();
      setState(() {
        mediumType = MediumType.encryption;
      });
      onAttemptDecryption(props);
    }

    if (props.messagesLength < 10) {
      props.onFetchNewest();
    }

    if (draft != null && draft.type == MatrixMessageTypes.text) {
      inputController.value = TextEditingValue(
        text: draft.body!,
        selection: TextSelection.fromPosition(
          TextPosition(offset: draft.body!.length),
        ),
      );
    }

    messagesController.addListener(() {
      final extentBefore = messagesController.position.extentBefore;
      final max = messagesController.position.maxScrollExtent;

      final limit = max - extentBefore;
      final atLimit = Platform.isAndroid ? limit < 1 : limit < -32;

      if (atLimit && !loadMore) {
        setState(() {
          loadMore = true;
        });
        props.onLoadMoreMessages();
      } else if (!atLimit && loadMore && !props.loading) {
        setState(() {
          loadMore = false;
        });
      }
    });
  }

  onCheatCode(_Props props) async {
    final store = StoreProvider.of<AppState>(context);

    setState(() {
      sending = false;
    });

    // try {
    //   await store.dispatch(mutateMessagesRoom(
    //     room: props.room,
    //   ));
    // } catch (error) {
    //   printError(error.toString());
    // }
  }

  onAttemptDecryption(_Props props) async {
    final store = StoreProvider.of<AppState>(context);
    final room = props.room;

    // dont attempt to decrypt if encryption is not enabled
    if (!room.encryptionEnabled) {
      return;
    }

    final hasDecryptable = selectHasDecryptableMessages(
      store,
      props.room.id,
    );

    // dont attempt to decrypt if all messages are already decrypted
    if (!hasDecryptable) {
      return;
    }

    final messages = store.state.eventStore.messages;
    final roomMessages = messages[props.room.id] ?? [];

    final List<Message> messagesDecrypted = await store.dispatch(
      decryptMessages(props.room, roomMessages),
    );

    await store.dispatch(addMessagesDecrypted(
      roomId: props.room.id,
      messages: messagesDecrypted,
    ));
  }

  onDidChange(_Props? propsOld, _Props props) {
    if (props.room.encryptionEnabled && mediumType != MediumType.encryption) {
      setState(() {
        mediumType = MediumType.encryption;
      });
      props.onUpdateDeviceKeys();
    }
  }

  onViewUserDetails({Message? message, String? userId, User? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
        userId: userId ?? message!.sender,
      ),
    );
  }

  onToggleEdit() {
    if (selectedMessage == null) return;

    setState(() {
      editing = !editing;
    });
  }

  onSendEdit(
    _Props props, {
    String? text,
    String? type = MatrixMessageTypes.text,
    Message? related,
  }) async {
    setState(() {
      sending = true;
    });

    await props.onSendMessage(
      body: text,
      type: type,
      related: related,
      edit: true,
    );

    inputController.clear();

    // TODO: consider keeping this enabled?
    // if (props.dismissKeyboardEnabled) {
    FocusScope.of(context).unfocus();
    // }

    setState(() {
      sending = false;
      editing = false;
      selectedMessage = null;
    });
  }

  onSendMessage(_Props props) async {
    setState(() {
      sending = true;
    });

    props.onSendMessage(
      body: inputController.text,
      type: MatrixMessageTypes.text,
    );

    inputController.clear();
    if (props.dismissKeyboardEnabled) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      sending = false;
      editing = false;
    });
  }

  onSendMedia(File rawFile, MessageType type, _Props props) async {
    final store = StoreProvider.of<AppState>(context);
    final encryptionEnabled = props.room.encryptionEnabled;

    setState(() {
      sending = true;
    });

    // Globally notify other widgets you're sending a message in this room
    store.dispatch(
      UpdateRoom(id: props.room.id, sending: true),
    );

    File? encryptedFile;
    EncryptInfo? info;

    printDebug('STUFFF');
    printDebug(rawFile.path);
    printDebug(rawFile.uri.toString());

    var file = await scrubMedia(localFile: rawFile);

    if (file == null) {
      file = rawFile;
    }

    try {
      if (encryptionEnabled) {
        info = EncryptInfo.generate();
        encryptedFile = await encryptMedia(localFile: file, info: info);
        info = info.copyWith(
          shasum: base64.encode(
            sha256.convert(encryptedFile!.readAsBytesSync().toList()).bytes,
          ),
        );
      }
    } catch (error) {
      // Globally notify other widgets you're sending a message in this room
      store.dispatch(
        UpdateRoom(id: props.room.id, sending: false),
      );
      rethrow;
    }

    final mxcData = await store.dispatch(
      uploadMedia(localFile: encryptedFile ?? file),
    );

    final mxcUri = mxcData['content_uri'] as String?;

    ///
    /// TODO: solve mounted issue with back navigation
    ///
    /// should not have to do this but unfortunately
    /// when navigating back from the preview screen and
    /// submitting a new draft message, a MatrixImage widget
    /// doesn't fire onMounted or initState. Could potentially
    /// have something to do with the Visibility widget
    if (mxcUri != null) {
      store.dispatch(fetchMedia(
        mxcUri: mxcUri,
        info: info,
      ));
    }

    final message = Message(
      url: mxcUri,
      type: type.value, // get matrix type string (m.image)
      body: path.basename(file.path),
    );

    if (props.room.encryptionEnabled) {
      store.dispatch(sendMessageEncrypted(
        roomId: props.room.id,
        message: message,
        file: file,
        info: info,
      ));
    } else {
      store.dispatch(sendMessage(
        roomId: props.room.id,
        message: message,
        file: file,
      ));
    }

    inputController.clear();

    if (props.dismissKeyboardEnabled) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      sending = false;
    });
  }

  onAddMedia(File file, MessageType type, _Props props) async {
    Navigator.pushNamed(
      context,
      Routes.chatMediaPreview,
      arguments: MediaPreviewArguments(
        roomId: props.room.id,
        mediaList: [file],
        onConfirmSend: () => onSendMedia(file, type, props),
      ),
    );
  }

  onToggleSelectedMessage(Message? message) {
    setState(() {
      selectedMessage = message;
    });

    if (message == null) {
      setState(() {
        editing = false;
      });
    }
  }

  onChangeMediumType({String? newMediumType, _Props? props}) {
    // noop
    if (mediumType == newMediumType) {
      return;
    }

    if (newMediumType == MediumType.encryption) {
      // if the room has not enabled encryption
      // confirm with the user first before
      // attempting it
      if (!props!.room.encryptionEnabled) {
        return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DialogEncryption(
            onAccept: () {
              props.onToggleEncryption();

              setState(() {
                mediumType = newMediumType;
              });
            },
          ),
        );
      }

      // Otherwise, only toggle the medium type
      setState(() {
        mediumType = newMediumType;
      });
    } else {
      // allow other mediums for messages
      // unless they've encrypted the room
      if (!props!.room.encryptionEnabled) {
        setState(() {
          mediumType = newMediumType;
        });
      }
    }
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
              props!.onToggleReaction(
                emoji: emoji,
                message: message,
              );

              Navigator.pop(context, false);
              onToggleSelectedMessage(null);
            }),
      ),
    );
  }

  onShowMediumMenu(context, _Props props) async {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

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
          enabled: !props.room.encryptionEnabled,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onChangeMediumType(
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
                      backgroundColor: const Color(Colours.greyDisabled),
                      child: SvgPicture.asset(
                        Assets.iconSendUnlockBeing,
                        color: Colors.white,
                        semanticsLabel: 'Switch to ${Strings.labelSendUnencrypted}',
                      ),
                    ),
                  ),
                  Text('Unencrypted'),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          enabled: props.room.direct,
          child: GestureDetector(
            onTap: !props.room.direct
                ? null
                : () {
                    Navigator.pop(context);
                    onChangeMediumType(
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
                      child: SvgPicture.asset(
                        Assets.iconSendLockSolidBeing,
                        color: Colors.white,
                        semanticsLabel: 'Switch to ${Strings.labelSendEncrypted}',
                      ),
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

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        onDidChange: onDidChange,
        onInitialBuild: onMounted,
        converter: (Store<AppState> store) => _Props.mapStateToProps(
          store,
          (ModalRoute.of(context)!.settings.arguments as ChatScreenArguments).roomId,
        ),
        builder: (context, props) {
          final height = MediaQuery.of(context).size.height;
          final viewInsets = EdgeInsets.fromWindowPadding(
            WidgetsBinding.instance!.window.viewInsets,
            WidgetsBinding.instance!.window.devicePixelRatio,
          );
          final keyboardInset = viewInsets.bottom;
          final closedInputPadding =
              !inputFieldNode.hasFocus && Platform.isIOS && Dimensions.buttonlessHeightiOS < height;
          final isScrolling = messagesController.hasClients && messagesController.offset != 0;

          var inputContainerColor = Colors.white;
          var backgroundColor = Theme.of(context).scaffoldBackgroundColor;

          if (Theme.of(context).brightness == Brightness.dark) {
            inputContainerColor = Theme.of(context).scaffoldBackgroundColor;
          }

          Widget appBar = AppBarChat(
            room: props.room,
            color: props.chatColorPrimary,
            badgesEnabled: props.roomTypeBadgesEnabled,
            onDebug: () {
              onCheatCode(props);
            },
            onBack: () {
              if (inputController.text.isNotEmpty) {
                props.onSaveDraftMessage(
                  body: inputController.text,
                  type: MatrixMessageTypes.text,
                );
              } else if (props.room.draft != null) {
                props.onClearDraftMessage();
              }

              Navigator.pop(context, false);
            },
          );

          if (selectedMessage != null) {
            final isUserSent = props.currentUser.userId == (selectedMessage?.sender ?? '');
            final backgroundColorDark = HSLColor.fromColor(backgroundColor);

            final backgroundLightness =
                backgroundColorDark.lightness > 0.2 ? backgroundColorDark.lightness : 0.2;
            backgroundColor =
                backgroundColorDark.withLightness(backgroundLightness - 0.2).toColor();

            appBar = AppBarMessageOptions(
              user: props.currentUser,
              room: props.room,
              message: selectedMessage,
              isUserSent: isUserSent,
              onEdit: () => onToggleEdit(),
              onDismiss: () => onToggleSelectedMessage(null),
              onDelete: () => props.onDeleteMessage(
                room: props.room,
                message: selectedMessage,
              ),
            );
          }

          return Scaffold(
            appBar: appBar as PreferredSizeWidget?,
            backgroundColor: backgroundColor,
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
                          MessageList(
                            editing: editing,
                            editorController: editorController,
                            roomId: props.room.id,
                            showAvatars: props.showAvatars,
                            selectedMessage: selectedMessage,
                            scrollController: messagesController,
                            onSendEdit: (text, related) => onSendEdit(
                              props,
                              text: text,
                              related: related,
                            ),
                            onSelectReply: props.onSelectReply,
                            onViewUserDetails: onViewUserDetails,
                            onToggleSelectedMessage: onToggleSelectedMessage,
                          ),
                          Positioned(
                            child: Loader(
                              loading: props.loading,
                            ),
                          ),
                          Positioned(
                            child: Visibility(
                              visible: props.room.lastBatch == null && props.messagesLength < 10,
                              child: GestureDetector(
                                onTap: () => props.onLoadMoreMessages(),
                                child: Container(
                                  height: Dimensions.buttonHeightMin,
                                  color: Theme.of(context).secondaryHeaderColor,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Load more messages',
                                        style: Theme.of(context).textTheme.bodyText2,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: inputContainerColor,
                      boxShadow: isScrolling
                          ? [BoxShadow(blurRadius: 6, offset: Offset(0, -4), color: Colors.black12)]
                          : [],
                    ),
                    child: AnimatedPadding(
                      duration: Duration(milliseconds: inputFieldNode.hasFocus ? 225 : 0),
                      padding: EdgeInsets.only(
                        bottom: closedInputPadding ? 16 : 0,
                      ),
                      child: ChatInput(
                        roomId: props.room.id,
                        sending: sending,
                        editing: editing,
                        editorController: editorController,
                        mediumType: mediumType,
                        focusNode: inputFieldNode,
                        enterSend: props.enterSendEnabled,
                        controller: inputController,
                        quotable: props.room.reply,
                        inset: keyboardInset,
                        onCancelReply: () => props.onSelectReply(null),
                        onChangeMethod: () => onShowMediumMenu(context, props),
                        onSubmitMessage: !editing
                            ? () => onSendMessage(props)
                            : () => onSendEdit(
                                  props,
                                  text: editorController.text,
                                  related: selectedMessage,
                                ),
                        onAddMedia: ({required File file, required MessageType type}) =>
                            onAddMedia(file, type, props),
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
  final User currentUser;
  final Room room;
  final String? userId;
  final bool loading;
  final int messagesLength;
  final bool enterSendEnabled;
  final bool showAvatars;
  final ThemeType themeType;
  final Color chatColorPrimary;
  final bool roomTypeBadgesEnabled;
  final bool dismissKeyboardEnabled;

  final Function onSendMessage;
  final Function onDeleteMessage;
  final Function onUpdateDeviceKeys;
  final Function onSaveDraftMessage;
  final Function onClearDraftMessage;
  final Function onLoadMoreMessages;
  final Function onFetchNewest;
  final Function onAcceptInvite;
  final Function onRejectInvite;
  final Function onToggleEncryption;
  final Function onToggleReaction;
  final Function onMarkRead;
  final Function onSelectReply;

  const _Props({
    required this.room,
    required this.themeType,
    required this.userId,
    required this.loading,
    required this.showAvatars,
    required this.messagesLength,
    required this.enterSendEnabled,
    required this.chatColorPrimary,
    required this.roomTypeBadgesEnabled,
    required this.dismissKeyboardEnabled,
    required this.onUpdateDeviceKeys,
    required this.onSendMessage,
    required this.onDeleteMessage,
    required this.onSaveDraftMessage,
    required this.onClearDraftMessage,
    required this.onLoadMoreMessages,
    required this.onFetchNewest,
    required this.onAcceptInvite,
    required this.onRejectInvite,
    required this.onToggleEncryption,
    required this.onToggleReaction,
    required this.onMarkRead,
    required this.onSelectReply,
    required this.currentUser,
  });

  @override
  List<Object?> get props => [
        room,
        userId,
        loading,
        enterSendEnabled,
        chatColorPrimary,
      ];

  static _Props mapStateToProps(Store<AppState> store, String? roomId) => _Props(
        currentUser: store.state.authStore.currentUser,
        room: selectRoom(id: roomId, state: store.state),
        showAvatars: selectRoom(id: roomId, state: store.state).totalJoinedUsers > 2 ||
            roomUsers(store.state, roomId).length > 2,
        themeType: store.state.settingsStore.themeSettings.themeType,
        userId: store.state.authStore.user.userId,
        roomTypeBadgesEnabled: store.state.settingsStore.roomTypeBadgesEnabled,
        dismissKeyboardEnabled: store.state.settingsStore.dismissKeyboardEnabled,
        enterSendEnabled: store.state.settingsStore.enterSendEnabled,
        loading: selectRoom(state: store.state, id: roomId).syncing,
        messagesLength: store.state.eventStore.messages.containsKey(roomId)
            ? store.state.eventStore.messages[roomId]?.length ?? 0
            : 0,
        onSelectReply: (Message? message) {
          store.dispatch(selectReply(roomId: roomId, message: message));
        },
        chatColorPrimary: selectChatColor(store, roomId),
        onUpdateDeviceKeys: () async {
          final room = store.state.roomStore.rooms[roomId]!;

          final usersDeviceKeys = await store.dispatch(
            fetchDeviceKeys(userIds: room.userIds),
          );

          store.dispatch(setDeviceKeys(usersDeviceKeys));
        },
        onSaveDraftMessage: ({String? body, String? type}) {
          store.dispatch(saveDraft(
            body: body,
            type: type,
            room: store.state.roomStore.rooms[roomId],
          ));
        },
        onClearDraftMessage: ({String? body, String? type}) {
          store.dispatch(clearDraft(
            room: store.state.roomStore.rooms[roomId],
          ));
        },
        onSendMessage: (
            {required String body, String? type, bool edit = false, Message? related}) async {
          if (roomId == null || body.isEmpty) return;

          final room = store.state.roomStore.rooms[roomId]!;

          final message = Message(
            body: body,
            type: type,
          );

          if (room.encryptionEnabled) {
            return store.dispatch(sendMessageEncrypted(
              roomId: room.id,
              message: message,
              related: related,
              edit: edit,
            ));
          }

          return store.dispatch(sendMessage(
            roomId: room.id,
            message: message,
            related: related,
            edit: edit,
          ));
        },
        onDeleteMessage: ({Message? message, Room? room}) {
          if (message != null && room != null) {
            store.dispatch(deleteMessage(message: message, room: room));
          }
        },
        onAcceptInvite: () {
          store.dispatch(acceptRoom(
            room: selectRoom(state: store.state, id: roomId),
          ));
        },
        onRejectInvite: () {
          store.dispatch(leaveRoom(
            room: selectRoom(state: store.state, id: roomId),
          ));
        },
        onMarkRead: () {
          store.dispatch(markRoomRead(roomId: roomId));
        },
        onFetchNewest: () {
          final room = selectRoom(id: roomId, state: store.state);

          store.dispatch(fetchMessageEvents(
            room: room,
            from: room.nextBatch,
          ));
        },
        onToggleReaction: ({Message? message, String? emoji}) {
          final room = selectRoom(id: roomId, state: store.state);

          store.dispatch(
            toggleReaction(room: room, message: message, emoji: emoji),
          );
        },
        onToggleEncryption: () {
          final room = selectRoom(id: roomId, state: store.state);
          store.dispatch(
            toggleRoomEncryption(room: room),
          );
        },
        onLoadMoreMessages: () {
          final room = selectRoom(state: store.state, id: roomId);

          // TODO: need to account for 25 reactions, for example. "Messages" are different to spec
          final messages = store.state.eventStore.messages[room.id] ?? [];
          final oldest =
              messages.isNotEmpty ? selectOldestMessage(messages) ?? Message() : Message();

          // fetch messages from the oldest cached batch
          return store.dispatch(fetchMessageEvents(
            room: room,
            from: oldest.prevBatch,
            timestamp: oldest.timestamp,
          ));
        },
      );
}

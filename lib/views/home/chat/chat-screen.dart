import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/events/messages/actions.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/chat-settings/selectors.dart';
import 'package:syphon/views/home/chat/widgets/chat-input.dart';
import 'package:syphon/views/home/chat/widgets/dialog-encryption.dart';
import 'package:syphon/views/home/chat/widgets/dialog-invite.dart';
import 'package:syphon/views/home/chat/widgets/message-list.dart';
import 'package:syphon/views/widgets/appbars/appbar-chat.dart';
import 'package:syphon/views/widgets/appbars/appbar-options-message.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class ChatViewArguements {
  final String? roomId;
  final String? title;

  // Improve loading times
  ChatViewArguements({this.roomId, this.title});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  bool sending = false;
  Message? selectedMessage;
  Map<String, Color>? senderColors;

  bool loadMore = false;
  String? mediumType = MediumType.plaintext;

  final inputFieldNode = FocusNode();
  final editorController = TextEditingController();
  final messagesController = ScrollController();
  final listViewController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @protected
  Future onMounted(_Props props) async {
    final draft = props.room.draft;

    // only marked if read receipts are enabled
    props.onMarkRead();

    if (props.room.invite) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DialogInvite(
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
    }

    if (props.messagesLength! < 10) {
      props.onLoadFirstBatch();
    }

    if (draft != null && draft.type == MessageTypes.TEXT) {
      editorController.value = TextEditingValue(
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

  @protected
  onDidChange(_Props? propsOld, _Props props) {
    if (props.room.encryptionEnabled && mediumType != MediumType.encryption) {
      setState(() {
        mediumType = MediumType.encryption;
      });
      props.onUpdateDeviceKeys();
    }
  }

  @override
  void dispose() {
    inputFieldNode.dispose();
    messagesController.dispose();
    super.dispose();
  }

  onViewUserDetails({Message? message, String? userId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        userId: userId ?? message!.sender,
      ),
    );
  }

  onSendMessage(_Props props) async {
    setState(() {
      sending = true;
    });
    props.onSendMessage(
      body: editorController.text,
      type: MessageTypes.TEXT,
    );
    editorController.clear();
    if (props.dismissKeyboardEnabled) {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      sending = false;
    });
  }

  onToggleSelectedMessage(Message? message) {
    setState(() {
      selectedMessage = message;
    });
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
              indicatorColor: Theme.of(context).accentColor,
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
                        semanticsLabel: Strings.semanticsSendArrow,
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
                        semanticsLabel: Strings.semanticsSendArrow,
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
          (ModalRoute.of(context)!.settings.arguments as ChatViewArguements).roomId,
        ),
        builder: (context, props) {
          final double height = MediaQuery.of(context).size.height;

          final closedInputPadding =
              !inputFieldNode.hasFocus && Platform.isIOS && Dimensions.buttonlessHeightiOS < height;

          final isScrolling = messagesController.hasClients && messagesController.offset != 0;

          Color inputContainerColor = Colors.white;

          if (Theme.of(context).brightness == Brightness.dark) {
            inputContainerColor = Theme.of(context).scaffoldBackgroundColor;
          }

          Widget appBar = AppBarChat(
            room: props.room,
            color: props.chatColorPrimary,
            badgesEnabled: props.roomTypeBadgesEnabled,
            onDebug: () {
              props.onCheatCode();
            },
            onBack: () {
              if (editorController.text.isNotEmpty) {
                props.onSaveDraftMessage(
                  body: editorController.text,
                  type: MessageTypes.TEXT,
                );
              } else if (props.room.draft != null) {
                props.onClearDraftMessage();
              }

              Navigator.pop(context, false);
            },
          );

          if (selectedMessage != null) {
            appBar = AppBarMessageOptions(
              room: props.room,
              message: selectedMessage,
              onDismiss: () => onToggleSelectedMessage(null),
              onDelete: () => props.onDeleteMessage(
                message: selectedMessage,
              ),
            );
          }

          return Scaffold(
            appBar: appBar as PreferredSizeWidget?,
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
                          MessageList(
                            roomId: props.room.id,
                            selectedMessage: selectedMessage,
                            scrollController: messagesController,
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
                              visible: props.room.lastHash == null,
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
                        mediumType: mediumType,
                        focusNode: inputFieldNode,
                        enterSend: props.enterSendEnabled,
                        controller: editorController,
                        quotable: props.room.reply,
                        sending: sending,
                        onCancelReply: () => props.onSelectReply(null),
                        onChangeMethod: () => onShowMediumMenu(context, props),
                        onSubmitMessage: () => onSendMessage(props),
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
  final String? userId;
  final bool loading;
  final int? messagesLength;
  final bool enterSendEnabled;
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
  final Function onLoadFirstBatch;
  final Function onAcceptInvite;
  final Function onRejectInvite;
  final Function onToggleEncryption;
  final Function onToggleReaction;
  final Function onCheatCode;
  final Function onMarkRead;
  final Function onSelectReply;

  const _Props({
    required this.room,
    required this.themeType,
    required this.userId,
    required this.loading,
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
    required this.onLoadFirstBatch,
    required this.onAcceptInvite,
    required this.onRejectInvite,
    required this.onToggleEncryption,
    required this.onToggleReaction,
    required this.onCheatCode,
    required this.onMarkRead,
    required this.onSelectReply,
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
      room: selectRoom(id: roomId, state: store.state),
      themeType: store.state.settingsStore.themeSettings.themeType,
      userId: store.state.authStore.user.userId,
      roomTypeBadgesEnabled: store.state.settingsStore.roomTypeBadgesEnabled,
      dismissKeyboardEnabled: store.state.settingsStore.dismissKeyboardEnabled,
      enterSendEnabled: store.state.settingsStore.enterSendEnabled,
      loading: selectRoom(state: store.state, id: roomId).syncing,
      messagesLength: store.state.eventStore.messages.containsKey(roomId)
          ? store.state.eventStore.messages[roomId]?.length
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
      onSaveDraftMessage: ({
        String? body,
        String? type,
      }) {
        store.dispatch(saveDraft(
          body: body,
          type: type,
          room: store.state.roomStore.rooms[roomId],
        ));
      },
      onClearDraftMessage: ({
        String? body,
        String? type,
      }) {
        store.dispatch(clearDraft(
          room: store.state.roomStore.rooms[roomId],
        ));
      },
      onSendMessage: ({required String body, String? type}) async {
        if (roomId == null || body.isEmpty) return;

        final room = store.state.roomStore.rooms[roomId]!;

        final message = Message(
          body: body,
          type: type,
        );

        if (room.encryptionEnabled) {
          return store.dispatch(sendMessageEncrypted(
            roomId: roomId,
            message: message,
          ));
        }

        return store.dispatch(sendMessage(
          room: room,
          message: message,
        ));
      },
      onDeleteMessage: ({
        Message? message,
      }) {
        if (message != null) {
          store.dispatch(deleteMessage(message: message));
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
      onLoadFirstBatch: () {
        final room = selectRoom(id: roomId, state: store.state);

        store.dispatch(fetchMessageEvents(
          room: room,
          from: room.nextHash,
          limit: 25,
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

        // load message from cold storage
        // TODO: paginate cold storage messages
        // final messages = roomMessages(store.state, roomId);
        // if (messages.length < room.messageIds.length) {
        //   printDebug(
        //       '[onLoadMoreMessages] loading from cold storage ${messages.length} ${room.messageIds.length}');
        //   return store.dispatch(
        //     loadMessageEvents(
        //       room: room,
        //       offset: messages.length,
        //     ),
        //   );
        // }

        // fetch messages beyond the oldest known message - lastHash
        return store.dispatch(fetchMessageEvents(
          room: room,
          from: room.lastHash,
          oldest: true,
        ));
      },
      onCheatCode: () async {
        // await store.dispatch(store.dispatch(generateDeviceId(
        //   salt: store.state.authStore.username,
        // )));

        final room = selectRoom(state: store.state, id: roomId);

        store.dispatch(updateKeySessions(room: room));

        final usersDeviceKeys = await store.dispatch(
          fetchDeviceKeys(userIds: room.userIds),
        );

        printJson(usersDeviceKeys);
      });
}

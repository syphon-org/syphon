import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:syphon/domain/crypto/events/actions.dart';
import 'package:syphon/domain/crypto/events/selectors.dart';
import 'package:syphon/domain/crypto/keys/actions.dart';
import 'package:syphon/domain/events/actions.dart';
import 'package:syphon/domain/events/messages/actions.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/selectors.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/media/actions.dart';
import 'package:syphon/domain/media/encryption.dart';
import 'package:syphon/domain/media/filters.dart';
import 'package:syphon/domain/rooms/actions.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/selectors.dart';
import 'package:syphon/domain/settings/chat-settings/selectors.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/domain/user/selectors.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/hooks.dart';

import 'package:syphon/global/libraries/matrix/events/types.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/views/home/chat/media-preview-screen.dart';
import 'package:syphon/views/home/chat/widgets/MessageList.dart';
import 'package:syphon/views/home/chat/widgets/chat-input.dart';
import 'package:syphon/views/home/chat/widgets/dialog-encryption.dart';
import 'package:syphon/views/home/chat/widgets/dialog-invite.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-chat.dart';
import 'package:syphon/views/widgets/appbars/appbar-options-message.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class ChatScreenArguments {
  final String? roomId;
  final String? title;

  ChatScreenArguments({this.roomId, this.title});
}

class ChatScreen extends HookWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatScreenArguments(:roomId) = useScreenArguments<ChatScreenArguments>(
      context,
      ChatScreenArguments(),
    );

    final dispatch = useDispatch<AppState>();
    final brightness = useBrightness(context);
    final EdgeInsets(:bottom) = useViewInsets(context);
    final Size(:height, :width) = useDimensions(context);

    final (sending, setSending) = useStateful<bool>(false);
    final (loadMore, setLoadMore) = useStateful<bool>(false);
    final (editing, setEditing) = useStateful<bool>(false);

    final (selectedMessage, setSelectedMessage) = useStateful<Message?>(null);
    final (mediumType, setMediumType) = useStateful<String>(MediumType.plaintext);

    final inputFieldNode = useFocusNode();
    final inputController = useTextEditingController();
    final editorController = useTextEditingController();
    final messagesController = useScrollController();

    final isScrolling = messagesController.hasClients && messagesController.offset != 0;
    final closedInputPadding =
        !inputFieldNode.hasFocus && Platform.isIOS && Dimensions.buttonlessHeightiOS < height;

    final hasSelectedMessage = selectedMessage != null;

    // Global App State
    final currentUser = useSelector<AppState, User>(
      (state) => state.authStore.user,
      User(),
    );
    final showAvatars = useSelector<AppState, bool>(
      (state) =>
          selectRoom(id: roomId, state: state).totalJoinedUsers > 2 || roomUsers(state, roomId).length > 2,
      true,
    );

    // Global Room State
    final room = useSelector<AppState, Room>(
      (state) => selectRoom(id: roomId, state: state),
      Room(id: ''),
    );
    final loading = useSelector<AppState, bool>(
      (state) => selectRoom(state: state, id: roomId).syncing,
      false,
    );
    final messages = useSelector<AppState, List<Message>>(
      (state) => state.eventStore.messages[roomId] ?? const [],
      const [],
    );
    final messagesLength = useSelector<AppState, int>(
      (state) => state.eventStore.messages[roomId]?.length ?? 0,
      0,
    );
    final hasDecryptables = useSelector<AppState, bool>(
      (state) => selectHasDecryptableMessages(state, roomId ?? ''),
      false,
    );

    // Global Chat Settings
    final chatColorPrimary = useSelector<AppState, Color>(
      (state) => selectChatColor(state, roomId),
      Color(AppColors.cyanSyphon),
    );
    final roomTypeBadgesEnabled = useSelector<AppState, bool>(
      (state) => state.settingsStore.roomTypeBadgesEnabled,
      false,
    );
    final dismissKeyboardEnabled = useSelector<AppState, bool>(
      (state) => state.settingsStore.dismissKeyboardEnabled,
      false,
    );
    final enterSendEnabled = useSelector<AppState, bool>(
      (state) => state.settingsStore.enterSendEnabled,
      false,
    );

    onSelectReply(Message? message) {
      dispatch(selectReply(roomId: roomId, message: message));
    }

    onUpdateDeviceKeys() async {
      final usersDeviceKeys = await dispatch(
        fetchDeviceKeys(userIds: room.userIds),
      );

      dispatch(setDeviceKeys(usersDeviceKeys));
    }

    onSaveDraftMessage({String? body, String? type}) {
      dispatch(
        saveDraft(
          body: body,
          type: type,
          room: room,
        ),
      );
    }

    onClearDraftMessage({String? body, String? type}) {
      dispatch(
        clearDraft(room: room),
      );
    }

    onSendMessage({
      required String body,
      String? type,
      bool edit = false,
      Message? related,
    }) async {
      if (roomId == null || body.isEmpty) return;

      final message = Message(body: body, type: type);

      if (room.encryptionEnabled) {
        return dispatch(
          sendMessageEncrypted(
            roomId: room.id,
            message: message,
            related: related,
            edit: edit,
          ),
        );
      }

      return dispatch(
        sendMessage(
          roomId: room.id,
          message: message,
          related: related,
          edit: edit,
        ),
      );
    }

    onDeleteMessage({Message? message, Room? room}) {
      if (message != null && room != null) {
        dispatch(deleteMessage(message: message, room: room));
      }
    }

    onAcceptInvite() {
      dispatch(acceptRoom(room: room));
    }

    onRejectInvite() {
      dispatch(
        leaveRoom(
          room: room,
        ),
      );
    }

    onMarkRead() {
      dispatch(markRoomRead(roomId: roomId));
    }

    onFetchNewest() {
      dispatch(
        fetchMessageEvents(
          room: room,
          from: room.nextBatch,
        ),
      );
    }

    onToggleEncryption() {
      dispatch(
        toggleRoomEncryption(room: room),
      );
    }

    onLoadMoreMessages() async {
      // TODO: need to account for 25 reactions, for example. "Messages" are different to spec
      final oldest = messages.isNotEmpty ? selectOldestMessage(messages) ?? Message() : Message();

      // fetch messages from the oldest cached batch
      final messagesNew = await dispatch(
        fetchMessageEvents(
          room: room,
          from: oldest.prevBatch,
          timestamp: oldest.timestamp,
        ),
      );

      console.debug('Found messages ${messagesNew.length}');
    }

    onAttemptDecryption() async {
      // dont attempt to decrypt if encryption is not enabled
      if (!room.encryptionEnabled) {
        return;
      }

      // dont attempt to decrypt if all messages are already decrypted
      if (!hasDecryptables) {
        return;
      }

      final List<Message> messagesDecrypted = await dispatch(
        decryptMessages(room, messages),
      );

      await dispatch(
        addMessagesDecrypted(
          roomId: room.id,
          messages: messagesDecrypted,
        ),
      );
    }

    useEffect(() {
      final Room(:draft) = room;

      // only marked if read receipts are enabled
      onMarkRead();

      if (room.invite) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogInvite(
            onAccept: onAcceptInvite,
            onReject: () {
              onRejectInvite();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pop(dialogContext);
            },
            onCancel: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pop(dialogContext);
            },
          ),
        );
      }

      if (room.encryptionEnabled) {
        onUpdateDeviceKeys();

        setMediumType(MediumType.encryption);
        onAttemptDecryption();
      }

      if (messagesLength < 10) {
        onFetchNewest();
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
          setLoadMore(true);
          onLoadMoreMessages();
        } else if (!atLimit && loadMore && !loading) {
          setLoadMore(false);
        }
      });
    }, []);

    useEffect(() {
      if (mediumType != MediumType.encryption && room.encryptionEnabled) {
        setMediumType(MediumType.encryption);
        onUpdateDeviceKeys();
        onAttemptDecryption();
      }

      return null;
    }, [room.encryptionEnabled]);

    onCheatCode() async {
      try {
        await dispatch(backfillDecryptMessages(room.id));
      } catch (error) {
        console.error(error.toString());
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
      setEditing(!editing);
    }

    onSendEdit({
      String? text,
      String? type = MatrixMessageTypes.text,
      Message? related,
    }) async {
      if (text == null) return;
      setSending(true);

      await onSendMessage(
        body: text,
        type: type,
        related: related,
        edit: true,
      );

      inputController.clear();

      FocusScope.of(context).unfocus();

      setSending(false);
      setEditing(false);
      setSelectedMessage(null);
    }

    onSendText() async {
      setSending(true);

      await onSendMessage(
        body: inputController.text,
        type: MatrixMessageTypes.text,
      );

      inputController.clear();

      if (dismissKeyboardEnabled) {
        FocusScope.of(context).unfocus();
      }

      setSending(false);
      setEditing(false);
    }

    onSendMedia(File rawFile, MessageType type) async {
      setSending(true);

      // Globally notify other widgets you're sending a message in this room
      dispatch(UpdateRoom(id: room.id, sending: true));

      File? encryptedFile;
      EncryptInfo? info;

      var file = await scrubMedia(
        localFile: rawFile,
        mediaNameFull: path.basename(rawFile.path),
      );

      if (file == null) {
        file = rawFile;
      }

      try {
        if (room.encryptionEnabled) {
          info = EncryptInfo.generate();
          encryptedFile = await encryptMedia(localFile: file, info: info);
          info = info.copyWith(
            shasum: base64.encode(
              Sha256().toSync().hashSync(encryptedFile!.readAsBytesSync().toList()).bytes,
            ),
          );
        }
      } catch (error) {
        // Globally notify other widgets you're sending a message in this room
        dispatch(
          UpdateRoom(id: room.id, sending: false),
        );
        rethrow;
      }

      final mxcData = await dispatch(
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
        dispatch(fetchMedia(mxcUri: mxcUri, info: info));
      }

      final message = Message(
        url: mxcUri,
        type: type.value, // get matrix type string (m.image)
        body: path.basename(file.path),
      );

      if (room.encryptionEnabled) {
        dispatch(sendMessageEncrypted(
          roomId: room.id,
          message: message,
          file: file,
          info: info,
        ));
      } else {
        dispatch(sendMessage(
          roomId: room.id,
          message: message,
          file: file,
        ));
      }

      inputController.clear();

      if (dismissKeyboardEnabled) {
        FocusScope.of(context).unfocus();
      }

      setSending(false);
    }

    onFocusChatInput() {
      inputFieldNode.requestFocus();
    }

    onAddMedia(
      File file,
      MessageType type,
    ) async {
      await Navigator.pushNamed(
        context,
        Routes.chatMediaPreview,
        arguments: MediaPreviewArguments(
          roomId: room.id,
          mediaList: [file],
          onConfirmSend: () => onSendMedia(file, type),
        ),
      );
    }

    onToggleSelectedMessage(Message? message) {
      setSelectedMessage(message);

      if (message == null) {
        setEditing(false);
      }
    }

    onChangeMediumType(String newMediumType) {
      // noop
      if (mediumType == newMediumType) return null;

      if (newMediumType == MediumType.encryption) {
        // if the room has not enabled encryption
        // confirm with the user first before
        // attempting it
        if (!room.encryptionEnabled) {
          return showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => DialogEncryption(
              onAccept: () {
                onToggleEncryption();
                setMediumType(newMediumType);
              },
            ),
          );
        }

        return setMediumType(newMediumType);
      }

      // allow other mediums for messages
      // unless they've encrypted the room
      if (!room.encryptionEnabled) {
        setMediumType(newMediumType);
      }
    }

    onShowMediumMenu(
      context,
    ) async {
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
            enabled: !room.encryptionEnabled,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onChangeMediumType(MediumType.plaintext);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        backgroundColor: const Color(AppColors.greyDisabled),
                        child: SvgPicture.asset(
                          Assets.iconSendUnlockBeing,
                          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
            enabled: room.direct,
            child: GestureDetector(
              onTap: !room.direct
                  ? null
                  : () {
                      Navigator.pop(context);
                      onChangeMediumType(MediumType.encryption);
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
                          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
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

    // toggles on selected message options in the AppBar
    final Widget appBar = useMemoized(() {
      if (hasSelectedMessage) {
        final isUserSent = currentUser.userId == (selectedMessage.sender ?? '');

        return AppBarMessageOptions(
          user: currentUser,
          room: room,
          message: selectedMessage,
          isUserSent: isUserSent,
          onEdit: () => onToggleEdit(),
          onReply: () => onFocusChatInput(),
          onDismiss: () => onToggleSelectedMessage(null),
          onDelete: () => onDeleteMessage(
            room: room,
            message: selectedMessage,
          ),
        );
      }

      return AppBarChat(
          room: room,
          color: chatColorPrimary,
          badgesEnabled: roomTypeBadgesEnabled,
          onDebug: () {
            onCheatCode();
          },
          onBack: () {
            if (inputController.text.isNotEmpty) {
              onSaveDraftMessage(
                body: inputController.text,
                type: MatrixMessageTypes.text,
              );
            } else if (room.draft != null) {
              onClearDraftMessage();
            }

            Navigator.pop(context, false);
          });
    }, [hasSelectedMessage]);

    // creates contrast from other messages when a message is selected
    final Color backgroundColor = useMemoized(() {
      final backgroundColorDefault = Theme.of(context).scaffoldBackgroundColor;
      if (!hasSelectedMessage) return backgroundColorDefault;

      final backgroundColorHSL = HSLColor.fromColor(backgroundColorDefault);

      final backgroundLightness = backgroundColorHSL.lightness > 0.2 ? backgroundColorHSL.lightness : 0.2;
      return backgroundColorHSL.withLightness(backgroundLightness - 0.2).toColor();
    }, [hasSelectedMessage]);

    final Color inputContainerColor = useMemoized(
      () => brightness == Brightness.dark ? backgroundColor : Colors.white,
      [brightness],
    );

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
                      key: Key(room.id),
                      roomId: room.id,
                      editing: editing,
                      editorController: editorController,
                      showAvatars: showAvatars,
                      selectedMessage: selectedMessage,
                      scrollController: messagesController,
                      onSendEdit: (text, related) => onSendEdit(
                        text: text,
                        related: related,
                      ),
                      onSelectReply: onSelectReply,
                      onViewUserDetails: onViewUserDetails,
                      onToggleSelectedMessage: onToggleSelectedMessage,
                    ),
                    Positioned(
                      child: Loader(
                        loading: loading,
                      ),
                    ),
                    Positioned(
                      child: Visibility(
                        visible: room.lastBatch == null && messagesLength < 10,
                        child: GestureDetector(
                          onTap: () => onLoadMoreMessages(),
                          child: Container(
                            height: Dimensions.buttonHeightMin,
                            color: Theme.of(context).secondaryHeaderColor,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Load more messages',
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                  roomId: room.id,
                  sending: sending,
                  editing: editing,
                  editorController: editorController,
                  mediumType: mediumType,
                  focusNode: inputFieldNode,
                  enterSend: enterSendEnabled,
                  controller: inputController,
                  quotable: room.reply,
                  inset: bottom,
                  onCancelReply: () => onSelectReply(null),
                  onChangeMethod: () => onShowMediumMenu(context),
                  onSubmitMessage: !editing
                      ? () => onSendText()
                      : () => onSendEdit(
                            text: editorController.text,
                            related: selectedMessage,
                          ),
                  onAddMedia: ({required File file, required MessageType type}) => onAddMedia(file, type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

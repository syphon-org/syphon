import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/receipts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/widgets/chat-mention.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/containers/media-card.dart';
import 'package:syphon/views/widgets/lists/list-local-images.dart';

const DEFAULT_BORDER_RADIUS = 24.0;

_empty({
  required File file,
  required MessageType type,
}) {}

class ChatInput extends StatefulWidget {
  final String roomId;
  final bool sending;
  final bool editing;
  final bool enterSend;
  final double inset;
  final Message? quotable;
  final String? mediumType;
  final FocusNode focusNode;
  final TextEditingController controller;
  final TextEditingController? editorController;

  final Function? onSubmitMessage;
  final Function? onChangeMethod;
  final Function? onUpdateMessage;
  final Function? onCancelReply;
  final Function({
    required File file,
    required MessageType type,
  }) onAddMedia;

  const ChatInput({
    Key? key,
    required this.roomId,
    required this.focusNode,
    required this.controller,
    this.editorController,
    this.mediumType,
    this.quotable,
    this.inset = 0,
    this.sending = false,
    this.editing = false,
    this.enterSend = false,
    this.onUpdateMessage,
    this.onChangeMethod,
    this.onSubmitMessage,
    this.onCancelReply,
    this.onAddMedia = _empty,
  }) : super(key: key);

  @override
  ChatInputState createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  ChatInputState() : super();

  bool mention = false;
  List<User?> users = [];

  bool sendable = false;
  bool showAttachments = false;

  double keyboardHeight = 0;

  Timer? typingNotifier;
  Timer? typingNotifierTimeout;

  String hintText = Strings.placeholderMatrixUnencrypted;

  onMounted(_Props props) {
    final draft = props.room.draft;

    if (draft != null && draft.type == MatrixMessageTypes.text) {
      setState(() {
        sendable = draft.body != null && draft.body!.isNotEmpty;
      });
    }

    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus) {
        setState(() {
          showAttachments = false;
        });
      }
      if (!widget.focusNode.hasFocus && typingNotifier != null) {
        typingNotifier!.cancel();
        setState(() {
          typingNotifier = null;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inset != keyboardHeight && widget.inset > keyboardHeight) {
      setState(() {
        keyboardHeight = widget.inset;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    if (typingNotifier != null) {
      typingNotifier!.cancel();
    }

    if (typingNotifierTimeout != null) {
      typingNotifierTimeout!.cancel();
    }
  }

  onUpdate(String text, {_Props? props}) {
    setState(() {
      sendable = text.trim().isNotEmpty;
    });

    // mention-dialog
    users = props!.users;
    mention = false;

    final cursorPos = widget.controller.selection.baseOffset;
    final subString = text.substring(0, cursorPos);

    final RegExp mentionExpEnd = RegExp(
      r'\B@\w+$',
      caseSensitive: false,
      multiLine: false,
    );

    final match = mentionExpEnd.firstMatch(subString);

    if (match != null) {
      final mention = subString.substring(match.start, match.end);
      final mentionName = mention.substring(1, mention.length);

      users = props.users.where((user) {
        return user != null &&
            user!.displayName!
                .toLowerCase()
                .contains(mentionName.toLowerCase());
      }).toList();

      setState(() {
        this.mention = users.isNotEmpty;
      });
    }

    // start an interval for updating typing status
    if (widget.focusNode.hasFocus && typingNotifier == null) {
      props!.onSendTyping(typing: true, roomId: props.room.id);
      setState(() {
        typingNotifier = Timer.periodic(
          Duration(milliseconds: 4000),
          (timer) => props.onSendTyping(typing: true, roomId: props.room.id),
        );
      });
    }

    // Handle a timeout of the interval if the user idles with input focused
    if (widget.focusNode.hasFocus) {
      if (typingNotifierTimeout != null) {
        typingNotifierTimeout!.cancel();
      }

      setState(() {
        typingNotifierTimeout = Timer(Duration(milliseconds: 4000), () {
          if (typingNotifier != null) {
            typingNotifier!.cancel();
            setState(() {
              typingNotifier = null;
              typingNotifierTimeout = null;
            });
            // run after to avoid flickering
            props!.onSendTyping(typing: false, roomId: props.room.id);
          }
        });
      });
    }
    widget.onUpdateMessage?.call(text);
  }

  onToggleMediaOptions() {
    // HACK: if nothing is focused yet, just open the media options
    if (!widget.focusNode.hasFocus && !showAttachments) {
      return onFocusSafe(
          focusNode: widget.focusNode,
          onFunction: () async {
            setState(() {
              showAttachments = !showAttachments;
            });
          });
    }

    widget.focusNode.unfocus();

    setState(() {
      showAttachments = !showAttachments;
    });
  }

  onSubmit() {
    setState(() {
      sendable = false;
    });
    widget.onSubmitMessage?.call();
  }

  onCancelReply() {
    widget.onCancelReply?.call();
  }

  onAddInProgress() {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(addInProgress());
  }

  onAddPhoto() async {
    // TODO: has bug with file path
    // final pickerResult = await ImagePicker().pickImage(
    //   source: ImageSource.gallery,
    // );

    final pickerResult = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );

    if (pickerResult == null) return;

    final file = File(pickerResult.path);

    widget.onAddMedia(file: file, type: MessageType.image);

    onToggleMediaOptions();
  }

  showDialogForPhotoPermission(BuildContext context){
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text(Strings.titleDialogPhotoPermission,
              style: TextStyle(fontWeight: FontWeight.w600),),
            content: Text(Strings.contentPhotoPermission),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(Strings.buttonCancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettings();
                },
                child: Text(Strings.buttonNext),
              ),
            ],
          ),
    );
  }

  onAddFile() async {
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (pickerResult == null) return;

    final file = File(pickerResult.paths[0]!);
    widget.onAddMedia(file: file, type: MessageType.file);
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) =>
            _Props.mapStateToProps(store, widget.roomId),
        onInitialBuild: onMounted,
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;
          final imageWidth = width * 0.48; // 2 images in view

          // dynamic dimensions
          final double messageInputWidth = width - 72;
          final bool replying =
              widget.quotable != null && widget.quotable!.sender != null;
          final bool loading = widget.sending;
          final double maxInputHeight =
              replying ? height * 0.45 : height * 0.65;
          final double maxMediaHeight =
              keyboardHeight > 0 ? keyboardHeight : height * 0.38;

          final imageHeight = keyboardHeight > 0
              ? maxMediaHeight * 0.65
              : imageWidth; // 2 images in view

          final isSendable = (sendable && !widget.sending) ||
              // account for if editing
              widget.editing &&
                  (widget.editorController?.text.isNotEmpty ?? false);

          final bool showMention = mention;

          Color sendButtonColor = const Color(AppColors.blueBubbly);

          if (widget.mediumType == MediumType.plaintext) {
            hintText = Strings.placeholderMatrixUnencrypted;
            sendButtonColor = Color(AppColors.greyDark);
          }

          if (widget.mediumType == MediumType.encryption) {
            hintText = Strings.placeholderMatrixEncrypted;
            sendButtonColor = Theme.of(context).primaryColor;
          }

          // if the button is disabled, make it more transparent to indicate that
          if (widget.sending) {
            sendButtonColor = Color(AppColors.greyDisabled);
          }

          var sendButton = Semantics(
            button: true,
            enabled: true,
            label: Strings.labelSendUnencrypted,
            child: InkWell(
              borderRadius: BorderRadius.circular(48),
              onLongPress: widget.onChangeMethod as void Function()?,
              onTap: !isSendable ? null : onSubmit,
              child: CircleAvatar(
                backgroundColor: sendButtonColor,
                child: Container(
                  margin: EdgeInsets.only(left: 2, top: 3),
                  child: SvgPicture.asset(
                    Assets.iconSendUnlockBeing,
                    color: Colors.white,
                    semanticsLabel: Strings.labelSendUnencrypted,
                  ),
                ),
              ),
            ),
          );

          if (widget.mediumType == MediumType.encryption) {
            sendButton = Semantics(
              button: true,
              enabled: true,
              label: Strings.labelSendEncrypted,
              child: InkWell(
                borderRadius: BorderRadius.circular(48),
                onLongPress: widget.onChangeMethod as void Function()?,
                onTap: loading || !isSendable ? null : onSubmit,
                child: CircleAvatar(
                  backgroundColor: sendButtonColor,
                  child: Container(
                    margin: EdgeInsets.only(left: 2, top: 3),
                    child: SvgPicture.asset(
                      Assets.iconSendLockSolidBeing,
                      color: Colors.white,
                      semanticsLabel: Strings.labelSendEncrypted,
                    ),
                  ),
                ),
              ),
            );
          }

          if (loading) {
            sendButton = Semantics(
              button: true,
              enabled: true,
              label: Strings.labelSendEncrypted,
              child: InkWell(
                borderRadius: BorderRadius.circular(48),
                onLongPress: widget.onChangeMethod as void Function()?,
                onTap: widget.sending || !isSendable ? null : onSubmit,
                child: CircleAvatar(
                  backgroundColor: sendButtonColor,
                  child: Container(
                    margin: EdgeInsets.only(left: 2, top: 3),
                    child: SvgPicture.asset(
                      Assets.iconSendLockSolidBeing,
                      color: Colors.white,
                      semanticsLabel: Strings.labelSendEncrypted,
                    ),
                  ),
                ),
              ),
            );
          }

          if (!isSendable) {
            sendButton = Semantics(
              button: true,
              enabled: true,
              label: Strings.labelShowAttachmentOptions,
              child: InkWell(
                borderRadius: BorderRadius.circular(48),
                onTap: widget.sending ? null : onToggleMediaOptions,
                child: CircleAvatar(
                  backgroundColor: sendButtonColor,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: Dimensions.iconSizeLarge,
                  ),
                ),
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //////// MENTION DIALOG ////////
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Mention(
                    visible: showMention,
                    width: MediaQuery.of(context).size.width -
                        Dimensions.buttonSendSize *
                            2.1, // HACK: fix the width of the dialog
                    users: users.whereNotNull().toList(),
                    controller: widget.controller,
                  )),
              Visibility(
                visible: replying,
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                //////// REPLY FIELD ////////
                child: Row(
                  children: <Widget>[
                    Stack(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: messageInputWidth,
                          ),
                          child: TextField(
                            maxLines: 1,
                            enabled: false,
                            autocorrect: false,
                            enableSuggestions: false,
                            controller: TextEditingController(
                              text: replying ? widget.quotable!.body : '',
                            ),
                            style: TextStyle(
                              color: props.inputTextColor,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              labelText:
                                  replying ? widget.quotable!.sender : '',
                              labelStyle: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                              contentPadding: Dimensions.inputContentPadding
                                  .copyWith(right: 36),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                  bottomLeft:
                                      Radius.circular(!replying ? 24 : 0),
                                  bottomRight:
                                      Radius.circular(!replying ? 24 : 0),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                  bottomLeft:
                                      Radius.circular(!replying ? 24 : 0),
                                  bottomRight:
                                      Radius.circular(!replying ? 24 : 0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            onPressed: () => onCancelReply(),
                            icon: Icon(
                              Icons.close,
                              size: Dimensions.iconSize,
                            ),
                            tooltip: Strings.tooltipCancelReply,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              //////// TEXT FIELD ////////
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: maxInputHeight,
                          maxWidth: messageInputWidth,
                        ),
                        child: Stack(
                          children: [
                            Visibility(
                              visible: widget.editing,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ButtonText(
                                    text: Strings.buttonSaveMessageEdit,
                                    size: 18.0,
                                    disabled: widget.sending || !isSendable,
                                    onPressed: () => onSubmit(),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: !widget.editing,
                              child: TextField(
                                maxLines: null,
                                autocorrect: props.autocorrectEnabled,
                                enableSuggestions: props.suggestionsEnabled,
                                textCapitalization: props.textCapitalization,
                                keyboardType: TextInputType.multiline,
                                textInputAction: widget.enterSend
                                    ? TextInputAction.send
                                    : TextInputAction.newline,
                                cursorColor: props.inputCursorColor,
                                focusNode: widget.focusNode,
                                controller: widget.controller,
                                onChanged: (text) =>
                                    onUpdate(text, props: props),
                                onSubmitted:
                                    !isSendable ? null : (text) => onSubmit(),
                                style: TextStyle(
                                  height: 1.5,
                                  color: props.inputTextColor,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  hintText: hintText,
                                  suffixIcon: Visibility(
                                    visible: isSendable,
                                    child: IconButton(
                                      color: Theme.of(context).iconTheme.color,
                                      onPressed: () => onToggleMediaOptions(),
                                      icon: Icon(
                                        Icons.add,
                                        size: Dimensions.iconSizeLarge,
                                      ),
                                    ),
                                  ),
                                  fillColor: props.inputColorBackground,
                                  contentPadding:
                                      Dimensions.inputContentPadding,
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(!replying
                                            ? DEFAULT_BORDER_RADIUS
                                            : 0),
                                        topRight: Radius.circular(!replying
                                            ? DEFAULT_BORDER_RADIUS
                                            : 0),
                                        bottomLeft: Radius.circular(
                                            DEFAULT_BORDER_RADIUS),
                                        bottomRight: Radius.circular(
                                            DEFAULT_BORDER_RADIUS),
                                      )),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(!replying
                                            ? DEFAULT_BORDER_RADIUS
                                            : 0),
                                        topRight: Radius.circular(!replying
                                            ? DEFAULT_BORDER_RADIUS
                                            : 0),
                                        bottomLeft: Radius.circular(
                                            DEFAULT_BORDER_RADIUS),
                                        bottomRight: Radius.circular(
                                            DEFAULT_BORDER_RADIUS),
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: Dimensions.buttonSendSize,
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: sendButton,
                      ),
                    ],
                  ),
                ],
              ),
              //////// MEDIA FIELD ////////
              Visibility(
                visible: showAttachments,
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                child: Container(
                  padding: EdgeInsets.only(top: 4),
                  constraints: BoxConstraints(
                    maxHeight: maxMediaHeight, // whole media field max height
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: width,
                          maxHeight:
                              imageHeight, // HACK: figure out why it overflows on Nexus 5x
                        ),
                        child: ListLocalImages(
                          imageSize: imageWidth,
                          onSelectImage: (file) {
                            widget.onAddMedia(
                              file: file,
                              type: MessageType.image,
                            );

                            onToggleMediaOptions();
                          },
                        ),
                      ),
                      Row(children: [
                        Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: MediaCard(
                            text: Strings.buttonGallery,
                            icon: Icons.photo,
                            onPress: () async{
                              const photosPermission = Permission.photos;
                              final status = await photosPermission.status;
                              if(!status.isGranted){
                                showDialogForPhotoPermission(context);
                              }else{
                                onAddPhoto();
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: MediaCard(
                            text: Strings.buttonFile,
                            icon: Icons.note_add,
                            onPress: () => onAddInProgress(),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: MediaCard(
                            text: Strings.buttonContact,
                            icon: Icons.person,
                            onPress: () => onAddInProgress(),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: MediaCard(
                            text: Strings.buttonLocation,
                            icon: Icons.near_me_rounded,
                            onPress: () => onAddInProgress(),
                          ),
                        ),
                      ])
                    ],
                  ),
                ),
              )
            ],
          );
        },
      );
}

class _Props extends Equatable {
  final Room room;
  final Color inputTextColor;
  final Color inputCursorColor;
  final Color inputColorBackground;
  final bool enterSendEnabled;
  final bool autocorrectEnabled;
  final bool suggestionsEnabled;
  final TextCapitalization textCapitalization;
  final List<User?> users;

  final Function onSendTyping;

  const _Props(
      {required this.room,
      required this.inputTextColor,
      required this.inputCursorColor,
      required this.inputColorBackground,
      required this.enterSendEnabled,
      required this.autocorrectEnabled,
      required this.suggestionsEnabled,
      required this.textCapitalization,
      required this.onSendTyping,
      required this.users});

  @override
  List<Object> get props => [
        room,
        enterSendEnabled,
      ];

  static _Props mapStateToProps(Store<AppState> store, String roomId) => _Props(
        room: selectRoom(id: roomId, state: store.state),
        users: roomUsers(store.state, roomId),
        inputTextColor: selectInputTextColor(
            store.state.settingsStore.themeSettings.themeType),
        inputCursorColor: selectCursorColor(
            store.state.settingsStore.themeSettings.themeType),
        inputColorBackground: selectInputBackgroundColor(
            store.state.settingsStore.themeSettings.themeType),
        enterSendEnabled: store.state.settingsStore.enterSendEnabled,
        autocorrectEnabled: store.state.settingsStore.autocorrectEnabled,
        suggestionsEnabled: store.state.settingsStore.suggestionsEnabled,
        textCapitalization: Platform.isIOS
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        onSendTyping: ({typing, roomId}) => store.dispatch(
          sendTyping(typing: typing, roomId: roomId),
        ),
      );
}

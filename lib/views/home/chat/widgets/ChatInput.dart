import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syphon/domain/alerts/actions.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/receipts/actions.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/selectors.dart';
import 'package:syphon/domain/settings/theme-settings/selectors.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/hooks.dart';

import 'package:syphon/global/libraries/matrix/events/types.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/home/chat/camera_screen.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/containers/media-card.dart';
import 'package:syphon/views/widgets/lists/list-local-images.dart';

const DEFAULT_BORDER_RADIUS = 24.0;

_empty({
  required File file,
  required MessageType type,
}) {}

class ChatInput extends HookWidget {
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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();
    final primaryColor = Theme.of(context).primaryColor;
    final Size(:height, :width) = useDimensions(context);
    final (sendable, setSendable) = useStateful<bool>(false);
    final (showAttachments, setShowAttachments) = useStateful<bool>(false);

    final (keyboardHeight, setKeyboardHeight) = useStateful<double>(0);

    final (typingNotifier, setTypingNotifier) = useStateful<Timer?>(null);
    final (typingNotifierTimeout, setTypingNotifierTimeout) = useStateful<Timer?>(null);

    final room = useSelector<AppState, Room>(
      (state) => selectRoom(id: roomId, state: state),
      const Room(id: ''),
    );

    // Global Chat Settings
    // TODO: not yet referenced
    // final enterSendEnabled = useSelector<AppState, bool>(
    //   (state) => state.settingsStore.enterSendEnabled,
    //   false,
    // );
    final autocorrectEnabled = useSelector<AppState, bool>(
      (state) => state.settingsStore.autocorrectEnabled,
      false,
    );
    final suggestionsEnabled = useSelector<AppState, bool>(
      (state) => state.settingsStore.suggestionsEnabled,
      false,
    );

    // Global Theming
    final inputTextColor = useSelector<AppState, Color>(
      (state) => selectInputTextColor(state.settingsStore.themeSettings.themeType),
      Colors.white,
    );

    final inputCursorColor = useSelector<AppState, Color>(
      (state) => selectCursorColor(state.settingsStore.themeSettings.themeType),
      Colors.white,
    );

    final inputColorBackground = useSelector<AppState, Color>(
      (state) => selectInputBackgroundColor(state.settingsStore.themeSettings.themeType),
      Colors.white,
    );

    // Local Theming
    final textCapitalization = useMemoized(
      () => Platform.isIOS ? TextCapitalization.sentences : TextCapitalization.none,
      [],
    );

    // dynamic dimensions
    final bool loading = sending;
    final bool replying = quotable != null && quotable!.sender != null;

    final double imageWidth = useMemoized(() => width * 0.48, [width]);
    final double messageInputWidth = useMemoized(() => width - 72, [width]);

    final double imageHeightMax = useMemoized(
      () => keyboardHeight > 0 ? keyboardHeight : height * 0.38,
      [keyboardHeight, height],
    );
    final double maxInputHeight = useMemoized(
      () => replying ? height * 0.45 : height * 0.65,
      [width, replying],
    );

    // 2 images in view
    final double imageHeight = useMemoized(
      () => keyboardHeight > 0 ? imageHeightMax * 0.65 : imageWidth,
      [keyboardHeight, imageHeightMax, imageWidth],
    );

    // account for if editing
    final isSendable = (sendable && !sending) || editing && (editorController?.text.isNotEmpty ?? false);

    useEffect(() {
      final Room(:draft) = room;

      if (draft != null && draft.type == MatrixMessageTypes.text) {
        setSendable(draft.body != null && draft.body!.isNotEmpty);
      }

      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          setShowAttachments(false);
        }
        if (!focusNode.hasFocus) {
          typingNotifier?.cancel();
          setTypingNotifier(null);
        }
      });
      return null;
    }, []);

    useEffect(() {
      if (inset > keyboardHeight) {
        setKeyboardHeight(inset);
      }
      return null;
    }, [keyboardHeight]);

    onUpdateInput(String text) {
      setSendable(text.trim().isNotEmpty);

      // start an interval for updating typing status
      if (focusNode.hasFocus && typingNotifier == null) {
        dispatch(sendTyping(typing: true, roomId: room.id));

        setTypingNotifier(Timer.periodic(
          const Duration(milliseconds: 4000),
          (timer) => dispatch(sendTyping(typing: true, roomId: room.id)),
        ));
      }

      // Handle a timeout of the interval if the user idles with input focused
      if (focusNode.hasFocus) {
        if (typingNotifierTimeout != null) {
          typingNotifierTimeout.cancel();
        }

        setTypingNotifierTimeout(Timer(const Duration(milliseconds: 4000), () {
          if (typingNotifier != null) {
            typingNotifier.cancel();
            setTypingNotifier(null);
            setTypingNotifierTimeout(null);
            // run after to avoid flickering
            dispatch(sendTyping(typing: true, roomId: room.id));
          }
        }));
      }

      onUpdateMessage?.call(text);
    }

    onToggleMediaOptions() {
      // HACK: if nothing is focused yet, just open the media options
      if (!focusNode.hasFocus && !showAttachments) {
        return onFocusSafe(
          focusNode: focusNode,
          onFunction: () async {
            setShowAttachments(!showAttachments);
          },
        );
      }

      focusNode.unfocus();
      setShowAttachments(!showAttachments);
    }

    onSubmit() {
      setSendable(false);
      onSubmitMessage?.call();
    }

    onAddInProgress() => dispatch(addInProgress());

    onAddPhoto() async {
      // TODO: has bug with file path
      final pickerResult = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      // final pickerResult = await ImagePicker().getImage(
      //   source: ImageSource.gallery,
      // );

      if (pickerResult == null) return;

      final file = File(pickerResult.path);

      onAddMedia(file: file, type: MessageType.image);

      onToggleMediaOptions();
    }

    showDialogForPhotoPermission(BuildContext context) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            Strings.titleDialogPhotoPermission,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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

    // ignore: unused_element
    onAddFile() async {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (pickerResult == null) return;

      final file = File(pickerResult.paths[0]!);
      onAddMedia(file: file, type: MessageType.file);
    }

    onOpenCamera() async {
      final cameras = await availableCameras();

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CameraScreen(
                  onAddMedia: onAddMedia,
                  cameras: cameras,
                )),
      );
    }

    var hintText = Strings.placeholderMatrixUnencrypted;
    var sendButtonColor = const Color(AppColors.blueBubbly);

    if (mediumType == MediumType.plaintext) {
      hintText = Strings.placeholderMatrixUnencrypted;
      sendButtonColor = const Color(AppColors.greyDark);
    }

    if (mediumType == MediumType.encryption) {
      hintText = Strings.placeholderMatrixEncrypted;
      sendButtonColor = primaryColor;
    }

    // if the button is disabled, make it more transparent to indicate that
    if (sending) {
      sendButtonColor = const Color(AppColors.greyDisabled);
    }

    var sendButton = Semantics(
      button: true,
      enabled: true,
      label: Strings.labelSendUnencrypted,
      child: InkWell(
        borderRadius: BorderRadius.circular(48),
        onLongPress: onChangeMethod as void Function()?,
        onTap: !isSendable ? null : onSubmit,
        child: CircleAvatar(
          backgroundColor: sendButtonColor,
          child: Container(
            margin: const EdgeInsets.only(left: 2, top: 3),
            child: SvgPicture.asset(
              Assets.iconSendUnlockBeing,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              semanticsLabel: Strings.labelSendUnencrypted,
            ),
          ),
        ),
      ),
    );

    if (mediumType == MediumType.encryption) {
      sendButton = Semantics(
        button: true,
        enabled: true,
        label: Strings.labelSendEncrypted,
        child: InkWell(
          borderRadius: BorderRadius.circular(48),
          onLongPress: onChangeMethod as void Function()?,
          onTap: loading || !isSendable ? null : onSubmit,
          child: CircleAvatar(
            backgroundColor: sendButtonColor,
            child: Container(
              margin: const EdgeInsets.only(left: 2, top: 3),
              child: SvgPicture.asset(
                Assets.iconSendLockSolidBeing,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
          onLongPress: onChangeMethod as void Function()?,
          onTap: sending || !isSendable ? null : onSubmit,
          child: CircleAvatar(
            backgroundColor: sendButtonColor,
            child: Container(
              margin: const EdgeInsets.only(left: 2, top: 3),
              child: SvgPicture.asset(
                Assets.iconSendLockSolidBeing,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
          onTap: sending ? null : onToggleMediaOptions,
          child: CircleAvatar(
            backgroundColor: sendButtonColor,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: Dimensions.iconSizeLarge,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
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
                        text: replying ? quotable!.body : '',
                      ),
                      style: TextStyle(
                        color: inputTextColor,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        labelText: replying ? quotable!.sender : '',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        contentPadding: Dimensions.inputContentPadding.copyWith(right: 36),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(24),
                            topRight: const Radius.circular(24),
                            bottomLeft: Radius.circular(!replying ? 24 : 0),
                            bottomRight: Radius.circular(!replying ? 24 : 0),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(24),
                            topRight: const Radius.circular(24),
                            bottomLeft: Radius.circular(!replying ? 24 : 0),
                            bottomRight: Radius.circular(!replying ? 24 : 0),
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
                      onPressed: () => onCancelReply?.call(),
                      icon: const Icon(
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
                    visible: editing,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ButtonText(
                          text: Strings.buttonSaveMessageEdit,
                          size: 18.0,
                          disabled: sending || !isSendable,
                          onPressed: () => onSubmit(),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: !editing,
                    child: SizedBox(
                      width: showAttachments ? width - 120 : width,
                      child: TextField(
                        maxLines: null,
                        autocorrect: autocorrectEnabled,
                        enableSuggestions: suggestionsEnabled,
                        textCapitalization: textCapitalization,
                        keyboardType: TextInputType.multiline,
                        textInputAction: enterSend ? TextInputAction.send : TextInputAction.newline,
                        cursorColor: inputCursorColor,
                        focusNode: focusNode,
                        controller: controller,
                        onChanged: (text) => onUpdateInput(text),
                        onSubmitted: !isSendable ? null : (text) => onSubmit(),
                        style: TextStyle(
                          height: 1.5,
                          color: inputTextColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          hintText: hintText,
                          suffixIcon: Visibility(
                            visible: isSendable,
                            child: IconButton(
                              color: Theme.of(context).iconTheme.color,
                              onPressed: () => onToggleMediaOptions(),
                              icon: const Icon(
                                Icons.add,
                                size: Dimensions.iconSizeLarge,
                              ),
                            ),
                          ),
                          fillColor: inputColorBackground,
                          contentPadding: Dimensions.inputContentPadding,
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(!replying ? DEFAULT_BORDER_RADIUS : 0),
                                topRight: Radius.circular(!replying ? DEFAULT_BORDER_RADIUS : 0),
                                bottomLeft: const Radius.circular(DEFAULT_BORDER_RADIUS),
                                bottomRight: const Radius.circular(DEFAULT_BORDER_RADIUS),
                              )),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(!replying ? DEFAULT_BORDER_RADIUS : 0),
                                topRight: Radius.circular(!replying ? DEFAULT_BORDER_RADIUS : 0),
                                bottomLeft: const Radius.circular(DEFAULT_BORDER_RADIUS),
                                bottomRight: const Radius.circular(DEFAULT_BORDER_RADIUS),
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: showAttachments,
              child: Container(
                width: Dimensions.buttonSendSize,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Semantics(
                  button: true,
                  enabled: true,
                  // label: Strings.labelSendUnencrypted,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(48),
                    onTap: () {
                      // print("Hi");
                      onOpenCamera();
                    },
                    child: CircleAvatar(
                      backgroundColor: sendButtonColor,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: Dimensions.buttonSendSize,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: sendButton,
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
            padding: const EdgeInsets.only(top: 4),
            constraints: BoxConstraints(
              maxHeight: imageHeightMax, // whole media field max height
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  constraints: BoxConstraints(
                    maxWidth: width,
                    maxHeight: imageHeight, // HACK: figure out why it overflows on Nexus 5x
                  ),
                  child: ListLocalImages(
                    imageSize: imageWidth,
                    onSelectImage: (file) {
                      onAddMedia(
                        file: file,
                        type: MessageType.image,
                      );

                      onToggleMediaOptions();
                    },
                  ),
                ),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: MediaCard(
                      text: Strings.buttonGallery,
                      icon: Icons.photo,
                      onPress: () async {
                        const photosPermission = Permission.photos;
                        final status = await photosPermission.status;
                        if (!status.isGranted) {
                          showDialogForPhotoPermission(context);
                        } else {
                          onAddPhoto();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: MediaCard(
                      text: Strings.buttonFile,
                      icon: Icons.note_add,
                      onPress: () => onAddInProgress(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: MediaCard(
                      text: Strings.buttonContact,
                      icon: Icons.person,
                      onPress: () => onAddInProgress(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
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
  }
}

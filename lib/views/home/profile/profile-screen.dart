import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:syphon/views/widgets/modals/modal-image-options.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  ProfileScreenState() : super();

  final title = Strings.titleProfile;
  final userIdController = TextEditingController();
  final displayNameController = TextEditingController();

  File? avatarFileNew;
  String? userIdNew;
  String? displayNameNew;

  onMounted(_Props props) {
    displayNameController.value = TextEditingValue(
      text: props.user.displayName!,
      selection: TextSelection.fromPosition(
        TextPosition(
          offset: props.user.displayName!.length,
        ),
      ),
    );

    userIdController.value = TextEditingValue(
      text: props.user.userId!,
      selection: TextSelection.fromPosition(
        TextPosition(
          offset: props.user.userId!.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    userIdController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  onShowImageOptions(context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ModalImageOptions(
        onSetNewAvatar: ({File? image}) {
          setState(() {
            avatarFileNew = image;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      onInitialBuild: onMounted,
      builder: (context, props) {
        const double imageSize = Dimensions.avatarSizeDetails;

        // Space for confirming rebuilding
        Widget avatarWidget = Avatar(
          uri: props.user.avatarUri,
          alt: formatUsername(props.user),
          size: imageSize,
          background: Colours.hashedColorUser(props.user),
        );

        if (avatarFileNew != null) {
          avatarWidget = Avatar(
            alt: formatUsername(props.user),
            size: imageSize,
            file: avatarFileNew,
            background: Colours.hashedColorUser(props.user),
          );
        }

        final backgroundColor = selectAvatarBackground(props.themeType);

        final hasNewInfo = avatarFileNew != null || displayNameNew != null || userIdNew != null;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w100,
              ),
            ),
          ),
          body: ScrollConfiguration(
            behavior: DefaultScrollBehavior(),
            child: SingleChildScrollView(
              // eventually expand as profile grows
              child: Container(
                padding: Dimensions.appPaddingHorizontal,
                constraints: BoxConstraints(
                  maxHeight: height * 0.9,
                  maxWidth: width,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Stack(
                            children: [
                              Container(
                                width: imageSize,
                                height: imageSize,
                                child: GestureDetector(
                                  onTap: () => onShowImageOptions(context),
                                  child: avatarWidget,
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 2,
                                child: Container(
                                  width: Dimensions.iconSizeLarge,
                                  height: Dimensions.iconSizeLarge,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.iconSizeLarge,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 6,
                                        offset: Offset(0, 0),
                                        color: Colors.black54,
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Theme.of(context).iconTheme.color,
                                    size: Dimensions.iconSizeLite,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      fit: FlexFit.loose,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsets.all(8.0),
                                constraints: BoxConstraints(
                                  maxHeight: Dimensions.inputHeight,
                                  maxWidth: Dimensions.inputWidthMax,
                                ),
                                child: TextFieldSecure(
                                  label: 'Display Name',
                                  controller: displayNameController,
                                  onChanged: (name) {
                                    setState(() {
                                      displayNameNew = name;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                  margin: const EdgeInsets.all(8.0),
                                  constraints: BoxConstraints(
                                    maxHeight: Dimensions.inputHeight,
                                    maxWidth: Dimensions.inputWidthMax,
                                  ),
                                  child: Row(children: [
                                    TextFieldSecure(
                                      disabled: false,
                                      readOnly: true,
                                      onChanged: null,
                                      enableInteractiveSelection: false,
                                      label: 'User ID',
                                      controller: userIdController,
                                      mouseCursor: MaterialStateMouseCursor.clickable,
                                      onTap: () async {
                                        await props.copyToClipboard();
                                      },
                                      suffix: IconButton(
                                        onPressed: () => props.copyToClipboard(),
                                        icon: Icon(Icons.copy),
                                      ),
                                    ),
                                  ])),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.all(8.0),
                                  child: ButtonSolid(
                                    text: Strings.buttonSave,
                                    loading: props.loading,
                                    disabled: props.loading || !hasNewInfo,
                                    onPressed: () async {
                                      final bool successful = await props.onSaveProfile(
                                        userIdNew: null,
                                        avatarFileNew: avatarFileNew,
                                        displayNameNew: displayNameNew,
                                      );
                                      if (successful) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  height: Dimensions.inputHeight,
                                  margin: const EdgeInsets.all(10.0),
                                  constraints: BoxConstraints(
                                    minWidth: Dimensions.buttonWidthMin,
                                    minHeight: Dimensions.buttonHeightMin,
                                  ),
                                  child: Visibility(
                                    child: TouchableOpacity(
                                      activeOpacity: 0.4,
                                      onTap: () => Navigator.pop(context),
                                      child: Text(
                                        Strings.buttonCancel,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w100,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Props extends Equatable {
  final User user;
  final bool loading;
  final ThemeType themeType;
  final Function onSaveProfile;
  final Function copyToClipboard;

  const _Props({
    required this.user,
    required this.loading,
    required this.themeType,
    required this.onSaveProfile,
    required this.copyToClipboard,
  });

  @override
  List<Object> get props => [
        user,
        loading,
        themeType,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
      user: store.state.authStore.user,
      loading: store.state.authStore.loading,
      themeType: store.state.settingsStore.themeSettings.themeType,
      onSaveProfile: ({
        File? avatarFileNew,
        String? userIdNew,
        String? displayNameNew,
      }) async {
        final currentUser = store.state.authStore.user;

        if (displayNameNew != null && currentUser.displayName != displayNameNew) {
          final bool successful = await store.dispatch(
            updateDisplayName(displayNameNew),
          );
          if (!successful) return false;
        }

        if (avatarFileNew != null) {
          final bool successful = await store.dispatch(
            updateAvatar(localFile: avatarFileNew),
          );
          if (!successful) return false;
        }

        await store.dispatch(fetchAuthUserProfile());
        return true;
      },
      copyToClipboard: () async {
        await Clipboard.setData(ClipboardData(text: store.state.authStore.user.userId));
        store.dispatch(addInfo(message: 'Copied User ID to clipboard')); //TODO i18n
      });
}

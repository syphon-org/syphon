// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/modals/modal-image-options.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  ProfileScreenState({Key? key}) : super();

  File? avatarFileNew;

  String? userIdNew;
  String? displayNameNew;

  final userIdController = TextEditingController();
  final displayNameController = TextEditingController();

  final String title = Strings.titleProfile;

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

    setState(() {
      displayNameNew = props.user.displayName;
    });
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
        final double imageSize = Dimensions.avatarSizeDetails;

        // Space for confirming rebuilding
        Widget avatarWidget = Avatar(
          uri: props.user.avatarUri,
          alt: formatUsername(props.user),
          size: imageSize,
          background: Colours.hashedColor(formatUsername(props.user)),
        );

        if (this.avatarFileNew != null) {
          avatarWidget = ClipRRect(
            borderRadius: BorderRadius.circular(imageSize),
            child: Image.file(
              this.avatarFileNew ?? props.user.avatarUri as File,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
            ),
          );
        }

        final backgroundColor = props.themeType.backgroundBrightness;

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
                                    boxShadow: [
                                      BoxShadow(
                                          blurRadius: 6,
                                          offset: Offset(0, 0),
                                          color: Colors.black54)
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
                                child: TextFieldSecure(
                                  disabled: true,
                                  onChanged: null,
                                  label: 'User ID',
                                  controller: userIdController,
                                ),
                              ),
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
                                    text: Strings.buttonSaveGeneric,
                                    loading: props.loading,
                                    disabled: props.loading ||
                                        displayNameNew ==
                                            props.user.displayName,
                                    onPressed: () async {
                                      final bool successful =
                                          await props.onSaveProfile(
                                        userIdNew: null,
                                        avatarFileNew: this.avatarFileNew,
                                        displayNameNew: this.displayNameNew,
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
                                        'cancel',
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

  _Props({
    required this.user,
    required this.themeType,
    required this.loading,
    required this.onSaveProfile,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        user: store.state.authStore.user,
        themeType: store.state.settingsStore.appTheme.themeType,
        loading: store.state.authStore.loading,
        onSaveProfile: ({
          File? avatarFileNew,
          String? userIdNew,
          String? displayNameNew,
        }) async {
          final currentUser = store.state.authStore.user;

          if (displayNameNew != null &&
              currentUser.displayName != displayNameNew) {
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
      );

  @override
  List<Object> get props => [
        user,
        loading,
      ];
}

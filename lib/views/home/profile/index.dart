import 'dart:io';

import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/image-matrix.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:image_picker/image_picker.dart';
import 'package:redux/redux.dart';

import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/selectors.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/modals/modal-image-options.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:syphon/global/behaviors.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key key}) : super(key: key);

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  ProfileViewState({Key key}) : super();

  File newAvatarFile;
  String newDisplayName;
  String newUserId;
  final displayNameController = TextEditingController();
  final userIdController = TextEditingController();
  final String title = Strings.titleProfile;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    displayNameController.value = TextEditingValue(
      text: store.state.authStore.user.displayName,
      selection: TextSelection.fromPosition(
        TextPosition(
          offset: store.state.authStore.user.displayName.length,
        ),
      ),
    );
    userIdController.value = TextEditingValue(
      text: store.state.authStore.user.userId,
      selection: TextSelection.fromPosition(
        TextPosition(
          offset: store.state.authStore.user.userId.length,
        ),
      ),
    );
  }

  @protected
  onShowBottomSheet(
    context,
  ) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) => ModalImageOptions(
        onSetNewAvatar: (File image) {
          this.setState(() {
            newAvatarFile = image;
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
      builder: (context, props) {
        final double imageSize = width * 0.28;
        final currentAvatar = props.user.avatarUri;

        // Space for confirming rebuilding
        dynamic avatarWidget = CircleAvatar(
          backgroundColor: Colors.grey,
          child: Text(
            displayInitials(props.user),
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.0,
            ),
          ),
        );

        if (this.newAvatarFile != null) {
          avatarWidget = ClipRRect(
            borderRadius: BorderRadius.circular(imageSize),
            child: Image.file(
              this.newAvatarFile ?? props.user.avatarUri,
              width: imageSize,
              height: imageSize,
            ),
          );
        } else if (currentAvatar != null) {
          avatarWidget = ClipRRect(
            borderRadius: BorderRadius.circular(imageSize),
            child: MatrixImage(
              fit: BoxFit.fill,
              mxcUri: props.user.avatarUri,
              width: imageSize,
              height: imageSize,
            ),
          );
        }

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
                padding: EdgeInsets.symmetric(horizontal: width * 0.075),
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
                                  onTap: () => onShowBottomSheet(context),
                                  child: avatarWidget,
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 2,
                                child: Container(
                                  width: width * 0.08,
                                  height: width * 0.08,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      width * 0.08,
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
                                    color: Theme.of(context).brightness !=
                                            Brightness.light
                                        ? Colors.grey[200]
                                        : Colors.grey[600],
                                    size: width * 0.06,
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
                                  child: TextField(
                                    onTap: () {},
                                    onChanged: (name) {
                                      this.setState(() {
                                        newDisplayName = name;
                                      });
                                    },
                                    controller: displayNameController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Display Name',
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(8.0),
                                  constraints: BoxConstraints(
                                    maxHeight: Dimensions.inputHeight,
                                    maxWidth: Dimensions.inputWidthMax,
                                  ),
                                  child: TextField(
                                    enabled: false,
                                    onChanged: null,
                                    controller: userIdController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'User ID',
                                    ),
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
                                      disabled: props.loading,
                                      onPressed: () async {
                                        final bool successful =
                                            await props.onSaveProfile(
                                          newUserId: null,
                                          newAvatarFile: this.newAvatarFile,
                                          newDisplayName: this.newDisplayName,
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
                                        minWidth: 200, minHeight: 45),
                                    child: Visibility(
                                      child: TouchableOpacity(
                                        activeOpacity: 0.4,
                                        onTap: () => Navigator.pop(context),
                                        child: Text(
                                          'quit editing',
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
                        )),
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
  final Function onSaveProfile;

  _Props({
    @required this.user,
    @required this.loading,
    @required this.onSaveProfile,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        user: store.state.authStore.user,
        loading: store.state.authStore.loading,
        onSaveProfile: ({
          File newAvatarFile,
          String newUserId,
          String newDisplayName,
        }) async {
          final currentUser = store.state.authStore.user;

          if (newDisplayName != null &&
              currentUser.displayName != newDisplayName) {
            final bool successful = await store.dispatch(
              updateDisplayName(newDisplayName),
            );
            if (!successful) return false;
          }

          if (newAvatarFile != null) {
            final bool successful = await store.dispatch(
              updateAvatarPhoto(localFile: newAvatarFile),
            );
            if (!successful) return false;
          }

          await store.dispatch(fetchUserProfile());
          return true;
        },
      );

  @override
  List<Object> get props => [
        user,
        loading,
      ];
}

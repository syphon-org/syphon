import 'dart:io';

import 'package:Tether/store/user/actions.dart';
import 'package:Tether/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:image_picker/image_picker.dart';
import 'package:redux/redux.dart';

import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/selectors.dart';

import 'package:Tether/global/dimensions.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/behaviors.dart';

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
  final String title = 'Set up Your Profile';

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
      text: store.state.userStore.user.displayName,
      selection: TextSelection.fromPosition(
        TextPosition(
          offset: store.state.userStore.user.displayName.length,
        ),
      ),
    );
    userIdController.value = TextEditingValue(
      text: store.state.userStore.user.userId,
      selection: TextSelection.fromPosition(
        TextPosition(
          offset: store.state.userStore.user.userId.length,
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
      builder: (BuildContext context) => Container(
        height: 250,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 24,
              ),
              child: Text(
                'Photo Select Method',
                textAlign: TextAlign.start,
              ),
            ),
            ListTile(
              onTap: () async {
                final File image = await ImagePicker.pickImage(
                  source: ImageSource.camera,
                );
                this.setState(() {
                  newAvatarFile = image;
                });
                print('onChangeAvatar $newAvatarFile');
                Navigator.pop(context);
              },
              leading: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.camera_alt,
                  size: 30,
                ),
              ),
              title: Text(
                'Take Photo',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            ListTile(
              onTap: () async {
                final File image = await ImagePicker.pickImage(
                  source: ImageSource.gallery,
                );
                this.setState(() {
                  newAvatarFile = image;
                });
                print('onChangeAvatar $newAvatarFile');
                Navigator.pop(context);
              },
              leading: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.photo_library,
                  size: 28,
                ),
              ),
              title: Text(
                'Pick from gallery',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
              },
              leading: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_forever,
                  size: 34,
                ),
              ),
              title: Text(
                'Remove photo',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          final double imageSize = width * 0.28;
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
                this.newAvatarFile,
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
                                        print('onChangedName $name');
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
                                      height: Dimensions.inputHeight,
                                      margin: const EdgeInsets.all(8.0),
                                      constraints: BoxConstraints(
                                        minWidth: Dimensions.buttonWidthMin,
                                        maxWidth: Dimensions.buttonWidthMax,
                                      ),
                                      child: FlatButton(
                                        disabledColor: Colors.grey,
                                        onPressed: !props.loading
                                            ? () async {
                                                final successful =
                                                    await props.onSaveProfile(
                                                  newUserId: null,
                                                  newAvatarFile:
                                                      this.newAvatarFile,
                                                  newDisplayName:
                                                      this.newDisplayName,
                                                );
                                                if (successful) {
                                                  Navigator.pop(context);
                                                }
                                              }
                                            : null,
                                        color: Theme.of(context).primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                        child: props.loading
                                            ? Container(
                                                constraints: BoxConstraints(
                                                  maxHeight: 28,
                                                  maxWidth: 28,
                                                ),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  backgroundColor: Colors.white,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.grey,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                'save',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white),
                                              ),
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
        });
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

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        user: store.state.userStore.user,
        loading: store.state.userStore.loading,
        onSaveProfile: ({
          File newAvatarFile,
          String newUserId,
          String newDisplayName,
        }) async {
          final currentUser = store.state.userStore.user;

          if (newDisplayName != null &&
              currentUser.displayName != newDisplayName) {
            final bool successful = await store.dispatch(
              updateDisplayName(newDisplayName),
            );
            if (!successful) return false;
          }

          if (newAvatarFile != null) {
            // final bool successful = await store.dispatch(
            //   updateAvatarPhoto(localFile: newAvatarFile),
            // );
            final bool successful = await store.dispatch(
              updateAvatarUri(
                mxcUri: 'mxc://matrix.org/dvbKIMzaFQWETZfKgSnOsnFs',
              ),
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

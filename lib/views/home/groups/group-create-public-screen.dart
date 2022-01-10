import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/buttons/button-text-opacity.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:syphon/views/widgets/lists/list-user-bubbles.dart';
import 'package:syphon/views/widgets/modals/modal-image-options.dart';

class CreatePublicGroupScreen extends StatefulWidget {
  const CreatePublicGroupScreen({Key? key}) : super(key: key);

  @override
  CreateGroupPublicState createState() => CreateGroupPublicState();
}

class CreateGroupPublicState extends State<CreatePublicGroupScreen> {
  CreateGroupPublicState() : super();

  File? avatar;
  String? name;
  String? topic;
  String? alias;

  final aliasFocus = FocusNode();
  final topicFocus = FocusNode();
  final nameController = TextEditingController();
  final topicController = TextEditingController();
  final aliasController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  onCreateRoom(_Props props) async {
    final roomId = await props.onCreateRoomPublic(
      avatar: avatar,
      name: name,
      topic: topic,
      alias: alias,
    );
    if (roomId != null) {
      Navigator.pop(context);
    }
  }

  onQuit(_Props props) async {
    props.onClearUserInvites();
    Navigator.pop(context);
  }

  onShowImageOptions() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ModalImageOptions(
        onSetNewAvatar: ({File? image}) {
          setState(() {
            avatar = image;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        rebuildOnChange: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          const double imageSize = Dimensions.avatarSizeDetails;

          final backgroundColor = selectAvatarBackground(props.themeType);

          // // Space for confirming rebuilding
          Widget avatarWidget = CircleAvatar(
            backgroundColor: backgroundColor,
            child: Icon(
              Icons.public,
              color: Theme.of(context).iconTheme.color,
              size: Dimensions.avatarSizeDetails / 1.4,
            ),
          );

          if (name != null && name!.isNotEmpty) {
            avatarWidget = CircleAvatar(
              backgroundColor: Colours.hashedColor(name),
              child: Text(
                formatInitialsLong(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Dimensions.avatarFontSize(size: imageSize),
                ),
              ),
            );
          }

          if (avatar != null) {
            avatarWidget = ClipRRect(
              borderRadius: BorderRadius.circular(imageSize),
              child: Image.file(
                avatar!,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    props.onClearUserInvites();
                    Navigator.pop(context, false);
                  }),
              title: Text(
                Strings.titleCreateGroupPublic,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: LayoutBuilder(
                builder: (
                  BuildContext context,
                  BoxConstraints viewportConstraints,
                ) =>
                    SingleChildScrollView(
                  // eventually expand as profile grows
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                        minWidth: viewportConstraints.maxWidth,
                      ),
                      child: IntrinsicHeight(
                        child: IntrinsicWidth(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Flexible(
                                      flex: 0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Stack(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(top: 42, bottom: 8),
                                                width: imageSize,
                                                height: imageSize,
                                                child: GestureDetector(
                                                  onTap: () => onShowImageOptions(),
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
                                          ),
                                          Container(
                                            padding: EdgeInsets.only(top: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.only(bottom: 4),
                                                  child: Text(
                                                    name ?? '',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodyText1,
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: alias != null && alias!.isNotEmpty,
                                                  maintainSize: true,
                                                  maintainState: true,
                                                  maintainAnimation: true,
                                                  child: Text(
                                                    formatAlias(
                                                      resource: alias ?? '',
                                                      homeserver: props.homeserver ?? '',
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.caption,
                                                  ),
                                                ),
                                                Flexible(
                                                    flex: 0,
                                                    fit: FlexFit.tight,
                                                    child: Container(
                                                      padding: EdgeInsets.only(top: 4),
                                                      constraints: BoxConstraints(
                                                        maxWidth: width / 1.5,
                                                      ),
                                                      child: Text(
                                                        topic ?? '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.center,
                                                        style: Theme.of(context).textTheme.caption,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      flex: 0,
                                      fit: FlexFit.loose,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Container(
                                                padding: Dimensions.listPadding,
                                                child: Text(
                                                  'About',
                                                  textAlign: TextAlign.start,
                                                  style: Theme.of(context).textTheme.subtitle2,
                                                ),
                                              ),
                                              Container(
                                                margin: Dimensions.inputMargin,
                                                constraints: BoxConstraints(
                                                  maxHeight: Dimensions.inputHeight,
                                                  maxWidth: Dimensions.inputWidthMax,
                                                ),
                                                child: TextFieldSecure(
                                                  label: 'Name*',
                                                  textInputAction: TextInputAction.next,
                                                  controller: nameController,
                                                  onSubmitted: (text) => FocusScope.of(context)
                                                      .requestFocus(aliasFocus),
                                                  onChanged: (text) => setState(() {
                                                    name = text;
                                                  }),
                                                ),
                                              ),
                                              Container(
                                                margin: Dimensions.inputMargin,
                                                constraints: BoxConstraints(
                                                  maxHeight: Dimensions.inputHeight,
                                                  maxWidth: Dimensions.inputWidthMax,
                                                ),
                                                child: TextFieldSecure(
                                                  label: 'Alias*',
                                                  textInputAction: TextInputAction.next,
                                                  disableSpacing: true,
                                                  focusNode: aliasFocus,
                                                  onSubmitted: (text) => FocusScope.of(context)
                                                      .requestFocus(topicFocus),
                                                  onChanged: (text) => setState(() {
                                                    alias = text;
                                                  }),
                                                  controller: aliasController,
                                                ),
                                              ),
                                              Container(
                                                margin: Dimensions.inputMargin,
                                                height: Dimensions.inputEditorHeight,
                                                constraints: BoxConstraints(
                                                  maxHeight: Dimensions.inputEditorHeight,
                                                  maxWidth: Dimensions.inputWidthMax,
                                                ),
                                                child: TextFieldSecure(
                                                  label: 'Topic',
                                                  maxLines: 25,
                                                  focusNode: topicFocus,
                                                  controller: topicController,
                                                  textInputAction: TextInputAction.newline,
                                                  onChanged: (text) => setState(() {
                                                    topic = text;
                                                  }),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      flex: 0,
                                      fit: FlexFit.loose,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                              top: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  Strings.labelUsers,
                                                  textAlign: TextAlign.start,
                                                  style: Theme.of(context).textTheme.subtitle2,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: Dimensions.avatarSizeLarge,
                                            width: width / 1.3,
                                            padding: EdgeInsets.only(left: 12),
                                            child: ListUserBubbles(
                                              users: props.users,
                                              invite: true,
                                              forceOption: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      flex: 0,
                                      child: Container(
                                        padding: EdgeInsets.only(top: 16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                              margin: const EdgeInsets.all(8.0),
                                              child: ButtonSolid(
                                                text: Strings.buttonCreate,
                                                loading: props.loading,
                                                disabled: props.loading,
                                                onPressed: () => onCreateRoom(props),
                                              ),
                                            ),
                                            Container(
                                              height: Dimensions.inputHeight,
                                              margin: const EdgeInsets.all(10.0),
                                              constraints: BoxConstraints(
                                                minWidth: Dimensions.buttonWidthMin,
                                                minHeight: Dimensions.buttonHeightMin,
                                              ),
                                              child: ButtonTextOpacity(
                                                text: Strings.buttonQuit,
                                                onPressed: () => onQuit(props),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType themeType;
  final String? homeserver;
  final List<User> users;

  final Function onCreateRoomPublic;
  final Function onClearUserInvites;

  const _Props({
    required this.users,
    required this.themeType,
    required this.loading,
    required this.homeserver,
    required this.onCreateRoomPublic,
    required this.onClearUserInvites,
  });

  @override
  List<Object?> get props => [
        users,
        themeType,
        loading,
        homeserver,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        users: store.state.userStore.invites,
        themeType: store.state.settingsStore.themeSettings.themeType,
        homeserver: store.state.authStore.user.homeserverName,
        loading: store.state.authStore.loading,
        onClearUserInvites: () => store.dispatch(
          clearUserInvites(),
        ),
        onCreateRoomPublic: ({
          File? avatar,
          String? name,
          String? topic,
          String? alias,
          List<User>? invites,
        }) async {
          final invites = store.state.userStore.invites;

          final result = await store.dispatch(createRoom(
            name: name,
            topic: topic,
            alias: alias,
            invites: invites,
            avatarFile: avatar,
            preset: RoomPresets.public,
          ));

          if (result != null) {
            store.dispatch(clearUserInvites());
          }
          return result;
        },
      );
}

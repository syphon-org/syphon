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
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/views/widgets/buttons/button-text-opacity.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:syphon/views/widgets/lists/list-user-bubbles.dart';
import 'package:syphon/views/widgets/modals/modal-image-options.dart';

// Project imports:
import 'package:syphon/global/behaviors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({Key key}) : super(key: key);

  @override
  CreateGroupPublicState createState() => CreateGroupPublicState();
}

class CreateGroupPublicState extends State<CreateGroupView> {
  CreateGroupPublicState({Key key}) : super();

  File avatar;
  String name;
  String topic;

  final topicFocus = FocusNode();
  final nameController = TextEditingController();
  final topicController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    /** noop */
  }

  @protected
  void onCreateRoom(_Props props) async {
    final roomId = await props.onCreateRoomPublic(
      avatar: this.avatar,
      name: this.name,
      topic: this.topic,
    );
    if (roomId != null) {
      Navigator.pop(context);
    }
  }

  @protected
  void onQuit(_Props props) async {
    props.onClearUserInvites();
    Navigator.pop(context);
  }

  @protected
  void onShowImageOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ModalImageOptions(
        onSetNewAvatar: ({File image}) {
          this.setState(() {
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
          final double imageSize = Dimensions.avatarSizeDetails;

          // // Space for confirming rebuilding
          Widget avatarWidget = CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(
              Icons.group,
              color: Theme.of(context).indicatorColor,
              size: Dimensions.avatarSizeDetails / 1.4,
            ),
          );

          if (this.name != null && this.name.isNotEmpty) {
            avatarWidget = CircleAvatar(
              backgroundColor: Colours.hashedColor(this.name),
              child: Text(
                formatInitials(this.name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Dimensions.avatarFontSize(size: imageSize),
                ),
              ),
            );
          }

          if (this.avatar != null) {
            avatarWidget = ClipRRect(
              borderRadius: BorderRadius.circular(imageSize),
              child: Image.file(
                this.avatar,
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
                Strings.titleCreateGroup,
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
                      FocusScope.of(context).requestFocus(new FocusNode());
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Stack(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(
                                                    top: 42, bottom: 8),
                                                width: imageSize,
                                                height: imageSize,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      onShowImageOptions(),
                                                  child: avatarWidget,
                                                ),
                                              ),
                                              Positioned(
                                                right: 6,
                                                bottom: 2,
                                                child: Container(
                                                  width:
                                                      Dimensions.iconSizeLarge,
                                                  height:
                                                      Dimensions.iconSizeLarge,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                    color: Theme.of(context)
                                                        .indicatorColor,
                                                    size:
                                                        Dimensions.iconSizeLite,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: EdgeInsets.only(top: 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.only(
                                                      bottom: 4),
                                                  child: Text(
                                                    this.name ?? '',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText1,
                                                  ),
                                                ),
                                                Flexible(
                                                    flex: 0,
                                                    fit: FlexFit.tight,
                                                    child: Container(
                                                      padding: EdgeInsets.only(
                                                          top: 4),
                                                      constraints:
                                                          BoxConstraints(
                                                        maxWidth: width / 1.5,
                                                      ),
                                                      child: Text(
                                                        this.topic ?? '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .caption,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Container(
                                                padding: Dimensions.listPadding,
                                                child: Text(
                                                  'About',
                                                  textAlign: TextAlign.start,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2,
                                                ),
                                              ),
                                              Container(
                                                margin: Dimensions.inputMargin,
                                                constraints: BoxConstraints(
                                                  maxHeight:
                                                      Dimensions.inputHeight,
                                                  maxWidth:
                                                      Dimensions.inputWidthMax,
                                                ),
                                                child: TextFieldSecure(
                                                  label: 'Name*',
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  controller: nameController,
                                                  onSubmitted: (text) =>
                                                      FocusScope.of(context)
                                                          .requestFocus(
                                                              topicFocus),
                                                  onChanged: (text) =>
                                                      this.setState(() {
                                                    name = text;
                                                  }),
                                                ),
                                              ),
                                              Container(
                                                margin: Dimensions.inputMargin,
                                                height: Dimensions
                                                    .inputEditorHeight,
                                                constraints: BoxConstraints(
                                                  maxHeight: Dimensions
                                                      .inputEditorHeight,
                                                  maxWidth:
                                                      Dimensions.inputWidthMax,
                                                ),
                                                child: TextFieldSecure(
                                                  label: 'Topic',
                                                  maxLines: 25,
                                                  focusNode: topicFocus,
                                                  controller: topicController,
                                                  textInputAction:
                                                      TextInputAction.newline,
                                                  onChanged: (text) =>
                                                      this.setState(() {
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  'Users',
                                                  textAlign: TextAlign.start,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                              margin: const EdgeInsets.all(8.0),
                                              child: ButtonSolid(
                                                text: Strings.buttonCreate,
                                                loading: props.loading,
                                                disabled: props.loading,
                                                onPressed: () =>
                                                    this.onCreateRoom(props),
                                              ),
                                            ),
                                            Container(
                                              height: Dimensions.inputHeight,
                                              margin:
                                                  const EdgeInsets.all(10.0),
                                              constraints: BoxConstraints(
                                                minWidth:
                                                    Dimensions.buttonWidthMin,
                                                minHeight:
                                                    Dimensions.buttonHeightMin,
                                              ),
                                              child: ButtonTextOpacity(
                                                text: Strings.buttonQuit,
                                                onPressed: () =>
                                                    this.onQuit(props),
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
  final String homeserver;
  final List<User> users;

  final Function onCreateRoomPublic;
  final Function onClearUserInvites;

  _Props({
    @required this.users,
    @required this.loading,
    @required this.homeserver,
    @required this.onCreateRoomPublic,
    @required this.onClearUserInvites,
  });

  @override
  List<Object> get props => [
        users,
        loading,
        homeserver,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        users: store.state.userStore.invites,
        homeserver: store.state.authStore.user.homeserverName,
        loading: store.state.authStore.loading,
        onClearUserInvites: () => store.dispatch(
          clearUserInvites(),
        ),
        onCreateRoomPublic: ({
          File avatar,
          String name,
          String topic,
          bool encryption,
          List<User> invites,
        }) async {
          final invites = store.state.userStore.invites;

          final result = await store.dispatch(createRoom(
            name: name,
            topic: topic,
            invites: invites,
            avatarFile: avatar,
            encryption: encryption,
            preset: RoomPresets.private,
          ));

          if (result != null) {
            store.dispatch(clearUserInvites());
          }
          return result;
        },
      );
}

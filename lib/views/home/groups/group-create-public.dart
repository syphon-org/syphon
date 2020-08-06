// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/views/widgets/buttons/button-text-opacity.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:syphon/views/widgets/modals/modal-image-options.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/global/behaviors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';

class CreateGroupPublicView extends StatefulWidget {
  const CreateGroupPublicView({Key key}) : super(key: key);

  @override
  CreateGroupPublicState createState() => CreateGroupPublicState();
}

class CreateGroupPublicState extends State<CreateGroupPublicView> {
  CreateGroupPublicState({Key key}) : super();

  File avatar;
  String name;
  String topic;
  String alias;

  final nameController = TextEditingController();
  final topicController = TextEditingController();
  final aliasController = TextEditingController();

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
  onShowImageOptions(context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ModalImageOptions(
        onSetNewAvatar: (File image) {
          this.setState(() {
            avatar = image;
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
        final double imageSize = Dimensions.avatarSizeDetails;

        // Space for confirming rebuilding
        Widget avatarWidget = CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(
            Icons.public,
            color: Theme.of(context).iconTheme.color,
            size: Dimensions.avatarSizeDetails / 1.4,
          ),
        );

        if (this.name != null && this.name.isNotEmpty) {
          avatarWidget = CircleAvatar(
            backgroundColor: Colors.grey,
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
              Strings.titleCreateGroupPublic,
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
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                                        color: Colors.grey,
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
                                        color:
                                            Theme.of(context).iconTheme.color,
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
                                        this.name ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .copyWith(color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      this.alias != null &&
                                              this.alias.isNotEmpty
                                          ? '@${this.alias}'
                                          : '',
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                  ],
                                ),
                              ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    padding: Dimensions.listPadding,
                                    child: Text(
                                      'About',
                                      textAlign: TextAlign.start,
                                      style:
                                          Theme.of(context).textTheme.subtitle2,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    constraints: BoxConstraints(
                                      maxHeight: Dimensions.inputHeight,
                                      maxWidth: Dimensions.inputWidthMax,
                                    ),
                                    child: TextFieldSecure(
                                      label: 'Name*',
                                      disableSpacing: true,
                                      controller: nameController,
                                      onChanged: (text) => this.setState(() {
                                        name = text;
                                      }),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    constraints: BoxConstraints(
                                      maxHeight: Dimensions.inputHeight,
                                      maxWidth: Dimensions.inputWidthMax,
                                    ),
                                    child: TextFieldSecure(
                                      label: 'Alias*',
                                      disableSpacing: true,
                                      onChanged: (text) => this.setState(() {
                                        alias = text;
                                      }),
                                      controller: aliasController,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    height: Dimensions.inputEditorHeight,
                                    constraints: BoxConstraints(
                                      maxHeight: Dimensions.inputEditorHeight,
                                      maxWidth: Dimensions.inputWidthMax,
                                    ),
                                    child: TextFieldSecure(
                                      label: 'Topic',
                                      maxLines: 25,
                                      controller: topicController,
                                      onChanged: (text) => this.setState(() {
                                        topic = text;
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
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
                                        onPressed: () async {
                                          final bool successful =
                                              await props.onCreateRoomPublic(
                                            name: this.name,
                                            topic: this.topic,
                                            alias: this.alias,
                                            avatar: this.avatar,
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
                                      child: ButtonTextOpacity(
                                        text: Strings.buttonQuit,
                                        onPressed: () => Navigator.pop(context),
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
  final bool loading;
  final List<User> users;
  final Function onCreateRoomPublic;

  _Props({
    @required this.users,
    @required this.loading,
    @required this.onCreateRoomPublic,
  });

  @override
  List<Object> get props => [
        users,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        users: friendlyUsers(store.state),
        loading: store.state.authStore.loading,
        onCreateRoomPublic: ({
          File avatar,
          String name,
          String topic,
          String alias,
        }) async {
          await store.dispatch(fetchUserCurrentProfile());
          return true;
        },
      );
}

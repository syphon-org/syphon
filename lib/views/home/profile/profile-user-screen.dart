import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';

class UserProfileArguments {
  final User? user;

  UserProfileArguments({this.user});
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfileScreen> {
  UserProfileState() : super();

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  double headerOpacity = 1;
  double headerSize = 54;
  List<User>? usersList;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final height = MediaQuery.of(context).size.height;
      const minOffset = 0;
      final maxOffset = height * 0.2;
      final offsetRatio = scrollController.offset / maxOffset;

      final isOpaque = scrollController.offset <= minOffset;
      final isTransparent = scrollController.offset > maxOffset;
      final isFading = !isOpaque && !isTransparent;

      if (isFading) {
        return setState(() {
          headerOpacity = 1 - offsetRatio;
        });
      }

      if (isTransparent) {
        return setState(() {
          headerOpacity = 0;
        });
      }

      return setState(() {
        headerOpacity = 1;
      });
    });
  }

  onBlockUser({required BuildContext context, _Props? props}) async {
    return await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DialogConfirm(
        title: 'Block User',
        content:
            'If you block ${props!.user.displayName}, you will not be able to see their messages and you will immediately leave this chat.',
        onConfirm: () async {
          await props.blockUser(props.user);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  onShowColorPicker({
    required context,
    required int originalColor,
    Function? onSelectColor,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => DialogColorPicker(
        title: 'Select User Color',
        currentColor: originalColor,
        onSelectColor: onSelectColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // Confirm this is needed in chat details
    final titlePadding = Dimensions.listTitlePaddingDynamic(width: width);
    final contentPadding = Dimensions.listPaddingDynamic(width: width);

    final UserProfileArguments arguments =
        ModalRoute.of(context)!.settings.arguments as UserProfileArguments;

    final user = arguments.user!;
    final userColor = Colours.hashedColor(user.userId);
    final scaffordBackgroundColor = Theme.of(context).brightness == Brightness.light
        ? Color(Colours.greyLightest)
        : Theme.of(context).scaffoldBackgroundColor;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store, user),
      builder: (context, props) => Scaffold(
        backgroundColor: scaffordBackgroundColor,
        body: CustomScrollView(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: height * 0.3,
              systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
              automaticallyImplyLeading: false,
              titleSpacing: 0.0,
              title: Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      user.displayName ?? user.userId!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ],
              ),
              flexibleSpace: Hero(
                tag: 'UserAvatar',
                child: Container(
                  padding: EdgeInsets.only(top: height * 0.075),
                  color: userColor,
                  width: width,
                  child: OverflowBox(
                    minHeight: 64,
                    maxHeight: height * 0.3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: headerOpacity,
                          child: Avatar(
                            size: height * 0.15,
                            uri: user.avatarUri,
                            alt: user.displayName ?? user.userId ?? '',
                            background: userColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
                delegate: SliverChildListDelegate([
              Container(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  children: <Widget>[
                    CardSection(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: width,
                            padding: titlePadding,
                            child: Text(
                              'About',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          Container(
                            padding: contentPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? '',
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                                Text(
                                  user.userId ?? '',
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                                Text(
                                  'User',
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: contentPadding,
                            child: Text(
                              'Chat Settings',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: contentPadding,
                            title: Text(
                              'Color',
                            ),
                            trailing: Container(
                              padding: EdgeInsets.only(right: 16),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: userColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: contentPadding,
                            child: Text(
                              'Privacy and Status',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: contentPadding,
                            title: Text('View Sessions'),
                          ),
                          ListTile(
                            onTap: () => onBlockUser(
                              context: context,
                              props: props,
                            ),
                            contentPadding: contentPadding,
                            title: Text('Block'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ])),
          ],
        ),
      ),
    );
  }
}

class _Props extends Equatable {
  final User user;
  final bool loading;

  final Function blockUser;
  final Function sendMessage;

  const _Props({
    required this.user,
    required this.loading,
    required this.blockUser,
    required this.sendMessage,
  });

  @override
  List<Object> get props => [
        user,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store, User user) => _Props(
        user: user,
        blockUser: (User user) async {
          await store.dispatch(toggleBlockUser(user: user));
        },
        sendMessage: () {
          // TODO: same as the modal
        },
        loading: store.state.roomStore.loading,
      );
}

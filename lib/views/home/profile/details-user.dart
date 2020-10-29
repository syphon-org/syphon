// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';

/**
 * Change to userId and 
 * create a global user store
 */
class UserDetailsArguments {
  final User user;

  // Improve loading times
  UserDetailsArguments({
    this.user,
  });
}

class UserDetailsView extends StatefulWidget {
  const UserDetailsView({Key key}) : super(key: key);

  @override
  UserDetailsState createState() => UserDetailsState();
}

class UserDetailsState extends State<UserDetailsView> {
  UserDetailsState({Key key}) : super();

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  double headerOpacity = 1;
  double headerSize = 54;
  List<User> usersList;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final height = MediaQuery.of(context).size.height;
      final minOffset = 0;
      final maxOffset = height * 0.2;
      final offsetRatio = scrollController.offset / maxOffset;

      final isOpaque = scrollController.offset <= minOffset;
      final isTransparent = scrollController.offset > maxOffset;
      final isFading = !isOpaque && !isTransparent;

      if (isFading) {
        return this.setState(() {
          headerOpacity = 1 - offsetRatio;
        });
      }

      if (isTransparent) {
        return this.setState(() {
          headerOpacity = 0;
        });
      }

      return this.setState(() {
        headerOpacity = 1;
      });
    });
  }

  @protected
  onShowColorPicker({
    context,
    int originalColor,
    Function onSelectColor,
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

    final UserDetailsArguments arguments =
        ModalRoute.of(context).settings.arguments;

    final user = arguments.user;
    final userColor = Colours.hashedColor(user.userId);
    final scaffordBackgroundColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.grey[200]
            : Theme.of(context).scaffoldBackgroundColor;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(
        store,
        user,
      ),
      builder: (context, props) => Scaffold(
        backgroundColor: scaffordBackgroundColor,
        body: CustomScrollView(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: height * 0.3,
              brightness: Theme.of(context).appBarTheme.brightness,
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
                      user.displayName ?? user.userId,
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
                tag: "UserAvatar",
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
                      child: Container(
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
                              // onTap: () => onShowColorPicker(
                              //   context: context,
                              //   onSelectColor: props.onSelectPrimaryColor,
                              //   originalColor: props.roomPrimaryColor.value,
                              // ),
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
                            title: Text(
                              'View Sessions',
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: contentPadding,
                            title: Text(
                              'Block',
                              // style: TextStyle(
                              //   fontSize: 18.0,
                              //   color: Colors.redAccent,
                              // ),
                            ),
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

  final Function onSendMessage;

  _Props({
    @required this.user,
    @required this.loading,
    @required this.onSendMessage,
  });

  @override
  List<Object> get props => [
        user,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store, User user) => _Props(
        onSendMessage: () {},
        loading: store.state.roomStore.loading,
      );
}

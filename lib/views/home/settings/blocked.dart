// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({Key key}) : super(key: key);

  @override
  BlockedUsersState createState() => BlockedUsersState();
}

class BlockedUsersState extends State<BlockedUsersView> {
  bool loading = false;

  BlockedUsersState({Key key});

  // componentDidMount(){}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @protected
  onShowUserDetails({
    BuildContext context,
    String userId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        userId: userId,
      ),
    );
  }

  @protected
  Widget buildUserList(BuildContext context, _Props props) => ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: props.usersBlocked.length,
        itemBuilder: (BuildContext context, int index) {
          final user = props.usersBlocked[index];

          return GestureDetector(
            onTap: () => this.onShowUserDetails(
              context: context,
              userId: user.userId,
            ),
            child: CardSection(
              padding: EdgeInsets.zero,
              elevation: 0,
              child: Container(
                child: ListTile(
                  leading: Avatar(
                    uri: user.avatarUri,
                    alt: user.displayName ?? user.userId,
                    size: Dimensions.avatarSizeMin,
                    background: Colours.hashedColor(
                      user.displayName ?? user.userId,
                    ),
                  ),
                  title: Text(
                    formatUsername(user),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  subtitle: Text(
                    user.userId,
                    style: Theme.of(context).textTheme.caption.merge(
                          TextStyle(
                            color: props.loading
                                ? Color(Colours.greyDisabled)
                                : null,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) => Scaffold(
        appBar: AppBar(
          title: Text('Blocked users'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Stack(
          children: [
            buildUserList(context, props),
            Positioned(
              child: Visibility(
                visible: this.loading,
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RefreshProgressIndicator(
                        strokeWidth: Dimensions.defaultStrokeWidth,
                        valueColor: new AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        value: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Props extends Equatable {
  final bool loading;
  final List<User> usersBlocked;

  _Props({
    @required this.loading,
    @required this.usersBlocked,
  });

  @override
  List<Object> get props => [
        loading,
        usersBlocked,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.roomStore.loading,
        usersBlocked: store.state.userStore.blocked
            .map((id) => store.state.userStore.users[id])
            .toList(),
      );
}

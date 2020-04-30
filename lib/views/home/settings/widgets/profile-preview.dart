import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/store/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:Tether/store/user/selectors.dart';

class ProfilePreview extends StatelessWidget {
  ProfilePreview({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          return Container(
            child: Container(
                child: Row(
              children: <Widget>[
                Container(
                  height: 56,
                  width: 56,
                  margin: EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Text(
                      props.initials,
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      props.displayName,
                      style: TextStyle(fontSize: 20.0),
                    ),
                    Text(
                      props.username,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                )
              ],
            )),
          );
        },
      );
}

class _Props extends Equatable {
  final String shortname;
  final String initials;
  final String username;
  final String avatarUri;
  final String displayName;

  _Props({
    @required this.shortname,
    @required this.username,
    @required this.initials,
    @required this.avatarUri,
    @required this.displayName,
  });

  static _Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      _Props(
          displayName: store.state.userStore.user.displayName,
          shortname: displayShortname(store.state.userStore.user),
          initials: displayInitials(store.state.userStore.user),
          avatarUri: store.state.userStore.user.avatarUri,
          username: store.state.userStore.user != null
              ? store.state.userStore.user.userId
              : '');

  @override
  List<Object> get props => [
        displayName,
        shortname,
        initials,
        username,
        avatarUri,
      ];
}

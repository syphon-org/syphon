import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:Tether/domain/user/selectors.dart';

class ProfilePreview extends StatelessWidget {
  ProfilePreview({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
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
                      props.shortname,
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

class Props {
  final String shortname;
  final String initials;
  final String username;

  Props({
    @required this.shortname,
    @required this.username,
    @required this.initials,
  });

  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
          shortname: displayShortname(store.state),
          initials: displayInitials(store.state),
          username: store.state.userStore.user != null
              ? store.state.userStore.user.userId
              : '');
  @override
  int get hashCode =>
      shortname.hashCode ^ username.hashCode ^ initials.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          shortname == other.shortname &&
          initials == other.initials &&
          username == other.username;
}

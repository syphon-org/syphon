import 'package:Tether/global/dimensions.dart';
import 'package:Tether/store/user/model.dart';
import 'package:Tether/store/user/selectors.dart';
import 'package:Tether/views/widgets/image-matrix.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/store/index.dart';

class ProfilePreview extends StatelessWidget {
  ProfilePreview({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          return Container(
            child: Row(
              children: <Widget>[
                Container(
                  height: 56,
                  width: 56,
                  margin: EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: props.avatarUri != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Dimensions.thumbnailSizeMax,
                            ),
                            child: MatrixImage(
                              width: 52,
                              height: 52,
                              mxcUri: props.avatarUri,
                            ),
                          )
                        : Text(
                            props.initials,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      props.user.displayName ?? '',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    Text(
                      props.username,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final User user;
  final String shortname;
  final String initials;
  final String username;
  final String avatarUri;

  _Props({
    @required this.shortname,
    @required this.username,
    @required this.initials,
    @required this.avatarUri,
    @required this.user,
  });

  // Lots of null checks in case the user signed out where
  // this widget is displaying, could probably be less coupled..
  static _Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      _Props(
          user: store.state.authStore.user ?? const User(),
          shortname: displayShortname(
            store.state.authStore.user ?? const User(),
          ),
          initials: displayInitials(
            store.state.authStore.user ?? const User(),
          ),
          avatarUri: (store.state.authStore.user ?? const User()).avatarUri,
          username: store.state.authStore.user != null
              ? store.state.authStore.user.userId
              : '');

  @override
  List<Object> get props => [
        user,
        shortname,
        initials,
        username,
        avatarUri,
      ];
}

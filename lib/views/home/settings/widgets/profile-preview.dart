import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:syphon/store/index.dart';

class ProfilePreview extends StatelessWidget {
  ProfilePreview({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) => Container(
          child: Row(
            children: <Widget>[
              Container(
                width: Dimensions.avatarSize,
                height: Dimensions.avatarSize,
                margin: EdgeInsets.only(right: 16),
                child: AvatarCircle(
                  uri: props.avatarUri,
                  alt: props.initials,
                  size: Dimensions.avatarSize,
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
                    props.username ?? '',
                    style: TextStyle(fontSize: 14.0),
                  ),
                ],
              )
            ],
          ),
        ),
      );
}

class _Props extends Equatable {
  final User user;
  final bool loading;
  final String shortname;
  final String initials;
  final String username;
  final String avatarUri;

  _Props({
    @required this.user,
    @required this.loading,
    @required this.shortname,
    @required this.username,
    @required this.initials,
    @required this.avatarUri,
  });

  @override
  List<Object> get props => [
        user,
        loading,
        shortname,
        initials,
        username,
        avatarUri,
      ];

  // Lots of null checks in case the user signed out where
  // this widget is displaying, could probably be less coupled..
  static _Props mapStateToProps(
    Store<AppState> store,
  ) =>
      _Props(
          user: store.state.authStore.user ?? const User(),
          loading: store.state.authStore.loading,
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
}

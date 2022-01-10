import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class ProfilePreview extends StatelessWidget {
  const ProfilePreview({
    Key? key,
    this.hasMultiaccounts = false,
    this.onModifyAccounts,
  }) : super(key: key);

  final bool hasMultiaccounts;
  final Function? onModifyAccounts;
  static const double avatarSize = 32;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props(store),
        builder: (context, props) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(children: [
              Container(
                width: Dimensions.avatarSize,
                height: Dimensions.avatarSize,
                margin: EdgeInsets.only(right: 16),
                child: Avatar(
                  uri: props.avatarUri,
                  alt: props.user.displayName ?? props.user.userId,
                  size: Dimensions.avatarSize,
                  background: Colours.hashedColorUser(props.user),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    props.username ?? '',
                    style: TextStyle(fontSize: 20.0),
                  ),
                  Text(
                    props.userId ?? '',
                    style: TextStyle(fontSize: 14.0),
                  ),
                ],
              ),
            ]),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: Dimensions.avatarSize,
                    height: Dimensions.avatarSize,
                    child: IconButton(
                      onPressed: () => onModifyAccounts != null ? onModifyAccounts!() : null,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: Color(Colours.greyDefault),
                        size: avatarSize,
                      ),
                    )),
              ],
            )
          ],
        ),
      );
}

///
/// TODO: Convert to cleaner ViewModel convention
/// https://github.com/brianegan/flutter_redux/issues/214
///
class _Props extends Equatable {
  // ignore: unused_field
  final Store<AppState> _store;

  final User user;
  final bool loading;
  final String? userId;
  final String? username;
  final String? avatarUri;

  @override
  List<Object?> get props => [
        user,
        userId,
        loading,
        username,
        avatarUri,
      ];

  _Props(this._store)
      : user = _store.state.authStore.user,
        userId = _store.state.authStore.user.userId,
        loading = _store.state.authStore.loading,
        username = formatUsername(_store.state.authStore.user),
        avatarUri = _store.state.authStore.user.avatarUri;
}

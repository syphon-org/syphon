import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/intro/login/login-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

class ModalContextSwitcher extends StatelessWidget {
  const ModalContextSwitcher() : super();

  onNavigateToMultiLogin({required BuildContext context, required _Props props}) async {
    Navigator.pushNamed(
      context,
      NavigationPaths.login,
      arguments: LoginScreenArguments(
        multiaccount: true,
      ),
    );
  }

  buildUserList(BuildContext context, _Props props) => ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.vertical,
      itemCount: props.availableUsers.length,
      itemBuilder: (BuildContext context, int index) {
        final user = props.availableUsers[index];

        return ListTile(
          selected: props.currentUser.userId == user.userId,
          onTap: () => props.onSwitchUser(user),
          contentPadding: EdgeInsets.zero,
          leading: Avatar(
            uri: user.avatarUri,
            alt: user.displayName ?? user.userId,
            size: Dimensions.avatarSizeMin,
            background: Colours.hashedColor(
              user.displayName ?? user.userId,
            ),
          ),
          title: Text(
            user.userId!,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyText2,
          ),
        );
      });

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) => Container(
            constraints: BoxConstraints(
              maxHeight: Dimensions.modalHeightMax,
            ),
            padding: Dimensions.modalPadding,
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Accounts',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.light
                              ? Color(Colours.greyDark)
                              : Color(Colours.whiteDefault),
                        ),
                  ),
                ),
                buildUserList(context, props),
                ListTile(
                  onTap: () => onNavigateToMultiLogin(
                    context: context,
                    props: props,
                  ),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Add account',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  leading: Container(
                    height: Dimensions.avatarSizeMin,
                    width: Dimensions.avatarSizeMin,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: Dimensions.iconSize,
                    ),
                  ),
                ),
              ],
            ),
          ));
}

class _Props extends Equatable {
  final bool loading;

  final User currentUser;
  final List<User> availableUsers;

  final Function onSwitchUser;

  const _Props({
    required this.loading,
    required this.currentUser,
    required this.availableUsers,
    required this.onSwitchUser,
  });

  @override
  List<Object> get props => [
        currentUser,
        availableUsers,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        currentUser: store.state.authStore.currentUser,
        availableUsers: store.state.authStore.availableUsers,
        onSwitchUser: (User user) {
          print(user);
          final contextObserver = store.state.authStore.contextObserver;
          contextObserver?.add(user);
        },
      );
}

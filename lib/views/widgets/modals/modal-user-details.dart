import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/home/profile/profile-user-screen.dart';
import 'package:syphon/views/home/search/search-rooms-screen.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';

class ModalUserDetails extends StatelessWidget {
  ModalUserDetails({
    Key? key,
    this.user,
    this.userId,
    this.nested,
  }) : super(key: key);

  final User? user;
  final String? userId;
  final bool? nested; // pop context twice when double nested in a view

  onNavigateToProfile({required BuildContext context, required _Props props}) async {
    Navigator.pushNamed(
      context,
      '/home/user/details',
      arguments: UserProfileArguments(
        user: props.user,
      ),
    );
  }

  onNavigateToInvite({required BuildContext context, required _Props props}) async {
    Navigator.pushNamed(
      context,
      '/home/rooms/search',
      arguments: RoomSearchArguments(
        user: props.user,
      ),
    );
  }

  onMessageUser({required BuildContext context, required _Props props}) async {
    final user = props.user;
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Chat with ${user.displayName}',
        content: Strings.confirmationStartChat,
        onStartChat: () async {
          final newRoomId = await props.onCreateChatDirect(user: user);

          Navigator.pop(context);

          if (nested!) {
            Navigator.pop(context);
          }

          if (newRoomId != null) {
            Navigator.popAndPushNamed(
              context,
              '/home/chat',
              arguments: ChatViewArguements(
                roomId: newRoomId,
                title: user.displayName,
              ),
            );
          }
        },
        onCancel: () async {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(
          store,
          user: user,
          userId: userId,
        ),
        builder: (context, props) => Container(
          constraints: BoxConstraints(
            maxHeight: Dimensions.defaultModalHeightMax,
          ),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Avatar(
                            uri: props.user.avatarUri,
                            alt: props.user.displayName ?? props.user.userId,
                            size: Dimensions.avatarSizeDetails,
                            background:
                                props.user.avatarUri == null ? Colours.hashedColor(props.user.userId) : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            props.user.displayName ?? '',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.subtitle1!.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          // wrapped with flexible to allow ellipsis
                          child: Text(
                            props.user.userId ?? '',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      onTap: () => this.onMessageUser(
                        context: context,
                        props: props,
                      ),
                      title: Text(
                        'Send A Message',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        margin: EdgeInsets.only(left: 2),
                        child: SvgPicture.asset(
                          Assets.iconMessageCircleBeing,
                          fit: BoxFit.contain,
                          width: Dimensions.iconSize - 2,
                          height: Dimensions.iconSize - 2,
                          semanticsLabel: 'Create A Public Room',
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () => this.onNavigateToInvite(
                        context: context,
                        props: props,
                      ),
                      title: Text(
                        'Invite To Room',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.mail_outline,
                          size: Dimensions.iconSize,
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () => this.onNavigateToProfile(
                        context: context,
                        props: props,
                      ),
                      title: Text(
                        'View Profile',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.info_outline,
                          size: Dimensions.iconSize,
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () async {
                        await props.onBlockUser(props.user);
                        Navigator.pop(context);
                      },
                      title: Text(
                        props.blocked ? 'Unblock User' : 'Block User',
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.block,
                          size: Dimensions.iconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Props extends Equatable {
  final User user;
  final Map<String, User> users;
  final bool blocked;
  final bool loading;
  final Function onBlockUser;
  final Function onCreateChatDirect;

  _Props({
    required this.user,
    required this.users,
    required this.loading,
    required this.blocked,
    required this.onCreateChatDirect,
    required this.onBlockUser,
  });

  @override
  List<Object> get props => [
        user,
        users,
      ];

  static _Props mapStateToProps(
    Store<AppState> store, {
    User? user,
    String? userId,
  }) =>
      _Props(
        user: () {
          if (user != null) {
            return user;
          }

          if (userId == null) {
            return User();
          }

          if (!store.state.userStore.users.containsKey(userId)) {
            store.dispatch(fetchUser(user: User(userId: userId)));
          }

          return store.state.userStore.users[userId] ?? User();
        }(),
        users: store.state.userStore.users,
        loading: store.state.userStore.loading,
        blocked: store.state.userStore.blocked.contains(userId ?? user!.userId),
        onBlockUser: (User user) async {
          await store.dispatch(toggleBlockUser(user: user));
        },
        onCreateChatDirect: ({required User user}) async => store.dispatch(
          createRoom(
            isDirect: true,
            invites: <User>[user],
          ),
        ),
      );
}

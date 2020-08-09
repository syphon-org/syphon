// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/home/profile/details-user.dart';
import 'package:syphon/views/home/search/search-rooms.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';

class ModalUserDetails extends StatelessWidget {
  ModalUserDetails({
    Key key,
    this.user,
    this.roomId,
    this.userId,
  }) : super(key: key);

  final User user;
  final String userId;
  final String roomId;

  @protected
  void onNavigateToProfile({BuildContext context, _Props props}) async {
    Navigator.pushNamed(
      context,
      '/home/user/details',
      arguments: UserDetailsArguments(
        user: props.user,
      ),
    );
  }

  @protected
  void onNavigateToInvite({BuildContext context, _Props props}) async {
    Navigator.pushNamed(
      context,
      '/home/rooms/search',
      arguments: RoomSearchArguments(
        user: props.user,
      ),
    );
  }

  @protected
  void onMessageUser({BuildContext context, _Props props}) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DialogStartChat(
        user: props.user,
        title: 'Chat with ${props.user.displayName}',
        content: Strings.confirmationStartChat,
        onStartChat: () async {
          final newRoomId = await props.onCreateChatDirect(user: props.user);
          Navigator.pop(context);
          Navigator.popAndPushNamed(
            context,
            '/home/chat',
            arguments: ChatViewArguements(
              roomId: newRoomId,
              title: formatUsername(props.user),
            ),
          );
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
          roomId: roomId,
          userId: userId,
        ),
        builder: (context, props) => Container(
          constraints: BoxConstraints(
            maxHeight: Dimensions.defaultModalHeightMax,
          ),
          padding: EdgeInsets.symmetric(
            vertical: 8,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(bottom: 16),
                          child: AvatarCircle(
                            uri: props.user.avatarUri,
                            alt: props.user.displayName ?? props.user.userId,
                            size: Dimensions.avatarSizeDetails,
                            background: props.user.avatarUri == null
                                ? Colours.hashedColor(props.user.userId)
                                : null,
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
                            style:
                                Theme.of(context).textTheme.subtitle1.copyWith(
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
              Container(
                child: Column(
                  children: <Widget>[
                    ListTile(
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
                      onTap: () => this.onMessageUser(
                        context: context,
                        props: props,
                      ),
                    ),
                    ListTile(
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
                      onTap: () => this.onNavigateToInvite(
                        context: context,
                        props: props,
                      ),
                    ),
                    ListTile(
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
                      onTap: () => this.onNavigateToProfile(
                        context: context,
                        props: props,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => props.onDisabled(),
                      child: ListTile(
                        enabled: false,
                        title: Text(
                          'Block',
                        ),
                        leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.block,
                            size: Dimensions.iconSize,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                        },
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

  final Function onDisabled;
  final Function onCreateChatDirect;

  _Props({
    @required this.user,
    @required this.onCreateChatDirect,
    @required this.onDisabled,
  });

  @override
  List<Object> get props => [
        user,
      ];

  static _Props mapStateToProps(
    Store<AppState> store, {
    User user,
    String userId,
    String roomId,
  }) =>
      _Props(
        user: () {
          if (user != null) {
            return user;
          }

          final room = store.state.roomStore.rooms[roomId];
          if (room != null) {
            return room.users[userId];
          }
          return null;
        }(),
        onDisabled: () => store.dispatch(
          addInfo(message: Strings.alertFeatureInProgress),
        ),
        onCreateChatDirect: ({User user}) async => store.dispatch(
          createRoom(
            isDirect: true,
            invites: <User>[user],
          ),
        ),
      );
}

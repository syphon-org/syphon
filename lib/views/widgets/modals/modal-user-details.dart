// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';

class ModalUserDetails extends StatelessWidget {
  ModalUserDetails({
    Key key,
    this.roomId,
    this.userId,
  }) : super(key: key);

  final String userId;
  final String roomId;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(
          store,
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
                        'Send a message',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        margin: EdgeInsets.only(left: 2),
                        child: SvgPicture.asset(
                          Assets.iconMessageSyphonBeing,
                          fit: BoxFit.contain,
                          width: Dimensions.iconSize,
                          height: Dimensions.iconSize,
                          semanticsLabel: 'Create A Public Room',
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Block',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.block,
                          size: Dimensions.iconSize,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      leading: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.info_outline,
                          size: Dimensions.iconSize,
                        ),
                      ),
                      title: Text(
                        'View profile',
                        style: Theme.of(context).textTheme.subtitle1,
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

class Props extends Equatable {
  final User user;

  Props({
    @required this.user,
  });

  @override
  List<Object> get props => [
        user,
      ];

  static Props mapStateToProps(
    Store<AppState> store, {
    String userId,
    String roomId,
  }) =>
      Props(
        user: () {
          final room = store.state.roomStore.rooms[roomId];
          if (room != null) {
            return room.users[userId];
          }
          return null;
        }(),
      );
}

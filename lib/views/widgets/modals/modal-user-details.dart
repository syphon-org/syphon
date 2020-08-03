import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';

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
      builder: (context, props) {
        return Container(
          height: Dimensions.modalHeightDefault(context),
          constraints: BoxConstraints(maxHeight: 800),
          padding: EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
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
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
                child: Text(
                  'Photo Select Method',
                  textAlign: TextAlign.start,
                ),
              ),
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                },
                leading: Container(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.camera_alt,
                    size: 30,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                },
                leading: Container(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.photo_library,
                    size: 28,
                  ),
                ),
                title: Text(
                  'Pick from gallery',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                },
                leading: Container(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_forever,
                    size: 34,
                  ),
                ),
                title: Text(
                  'Remove photo',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
            ],
          ),
        );
      });
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
          print('$roomId, $userId');
          if (room != null) {
            return room.users[userId];
          }
          return null;
        }(),
      );
}

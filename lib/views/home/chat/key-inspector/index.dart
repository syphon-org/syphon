import 'package:syphon/store/crypto/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';

class DialogKeyInspector extends StatelessWidget {
  DialogKeyInspector({
    Key key,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  final Function onConfirm;
  final Function onCancel;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        double width = MediaQuery.of(context).size.width;

        final double defaultWidgetScaling = width * 0.725;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: defaultWidgetScaling,
                    margin: const EdgeInsets.only(
                      top: 16,
                      bottom: 16,
                      left: 8,
                    ),
                    child: Text(
                      props.chatDeviceKeys.toString(),
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: !props.loading
                        ? () {
                            if (this.onCancel != null) {
                              this.onCancel();
                            }
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ],
              )
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final bool loading;
  final Map<String, Map<String, DeviceKey>> chatDeviceKeys;

  _Props({
    @required this.loading,
    @required this.chatDeviceKeys,
  });

  @override
  List<Object> get props => [
        loading,
        chatDeviceKeys,
      ];

  static _Props mapStateToProps(
    Store<AppState> store, {
    Room room,
  }) =>
      _Props(
        loading: false,
        chatDeviceKeys:
            store.state.cryptoStore.deviceKeys.map((userId, devices) {
          // Only return entries in this room
          if (!room.users.containsKey(userId)) {
            return null;
          }

          return MapEntry(userId, devices);
        }),
      );
}

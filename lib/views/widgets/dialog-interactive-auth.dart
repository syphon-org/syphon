import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:Tether/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:Tether/store/index.dart';

class DialogInteractiveAuth extends StatelessWidget {
  DialogInteractiveAuth({Key key}) : super(key: key);

  // TODO: onConfirm
  // After sending confirm, retry the on* handler that prompted the auth
  // You should create this by passing the function as a prop to this widget

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
      distinct: true,
      converter: (Store<AppState> store) => Props.mapStoreToProps(store),
      builder: (context, props) {
        double width = MediaQuery.of(context).size.width;

        final double defaultWidgetScaling = width * 0.725;
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.only(
            left: 24,
            right: 16,
            top: 16,
            bottom: 16,
          ),
          contentPadding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          title: Text(
            StringStore.deleteDevicesTitle,
          ),
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
                    StringStore.deleteDevicesConfirmation,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                Container(
                  width: defaultWidgetScaling,
                  height: Dimensions.inputHeight,
                  margin: const EdgeInsets.only(
                    bottom: 32,
                  ),
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: TextField(
                    onChanged: (password) {
                      props.onSetPassword(password);
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(
                        left: 20,
                        top: 32,
                        bottom: 32,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      labelText: 'password',
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('Confirm'),
                  onPressed: () {},
                ),
              ],
            )
          ],
        );
      });
}

class Props extends Equatable {
  final bool loading;
  final List<DeviceSetting> devices;
  final Map interactiveAuths;

  final Function onSetPassword;

  Props({
    @required this.loading,
    @required this.devices,
    @required this.interactiveAuths,
    @required this.onSetPassword,
  });

  @override
  List<Object> get props => [
        loading,
        devices,
        interactiveAuths,
      ];

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
          loading: store.state.settingsStore.loading,
          devices: store.state.settingsStore.devices ?? const [],
          interactiveAuths: store.state.authStore.interactiveAuths,
          onSetPassword: (password) {
            store.dispatch(setPassword(password: password));
          });
}

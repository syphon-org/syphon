import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/store/index.dart';

class ModalDetailsUser extends StatelessWidget {
  ModalDetailsUser({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
      distinct: true,
      converter: (Store<AppState> store) => Props.mapStateToProps(store),
      builder: (context, props) {
        return Container();
      });
}

class Props extends Equatable {
  final bool valid;
  final bool loading;
  final List<Device> devices;

  final Function onChangePassword;

  Props({
    @required this.valid,
    @required this.loading,
    @required this.devices,
    @required this.onChangePassword,
  });

  @override
  List<Object> get props => [
        valid,
        loading,
        devices,
      ];

  static Props mapStateToProps(
    Store<AppState> store,
  ) =>
      Props(
        valid: store.state.authStore.credential.value != null &&
            store.state.authStore.credential.value.length > 0,
        loading: store.state.settingsStore.loading,
        devices: store.state.settingsStore.devices ?? const [],
        onChangePassword: (password) {
          store.dispatch(updateCredential(value: password));
        },
      );
}

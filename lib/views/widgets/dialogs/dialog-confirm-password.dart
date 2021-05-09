// Flutter imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';

class DialogConfirmPassword extends StatelessWidget {
  DialogConfirmPassword({
    Key key,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  final Function onConfirm;
  final Function onCancel;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
      distinct: true,
      converter: (Store<AppState> store) => Props.mapStateToProps(store),
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
            tr('title-delete-devices'),
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
                    Strings.contentDeleteDevices,
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
                      props.onChangePassword(password);
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
                TextButton(
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
                TextButton(
                  child: !props.loading
                      ? Text('Confirm')
                      : Container(
                          constraints: BoxConstraints(
                            maxHeight: 16,
                            maxWidth: 16,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: Dimensions.defaultStrokeWidth,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        ),
                  onPressed: !props.valid
                      ? null
                      : () {
                          if (this.onConfirm != null) {
                            this.onConfirm();
                          }
                          Navigator.of(context).pop();
                        },
                ),
              ],
            )
          ],
        );
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

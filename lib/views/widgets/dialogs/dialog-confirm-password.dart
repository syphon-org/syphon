import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/views/widgets/loader/loading-indicator.dart';

class DialogConfirmPassword extends StatelessWidget {
  const DialogConfirmPassword({
    Key? key,
    required this.title, // i18n Strings isn't a constant. You gotta pass it in
    required this.content, // i18n Strings isn't a constant. You gotta pass it in
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  final String title;
  final String content;
  final Function? onConfirm;
  final Function? onCancel;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
      distinct: true,
      converter: (Store<AppState> store) => Props.mapStateToProps(store),
      builder: (context, props) {
        final double width = MediaQuery.of(context).size.width;

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
          title: Text(title),
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
                    content,
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
                      labelText: Strings.labelPassword,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: !props.loading
                      ? () {
                          if (onCancel != null) {
                            onCancel!();
                          }
                        }
                      : null,
                  child: Text(
                    Strings.buttonCancel,
                  ),
                ),
                TextButton(
                  onPressed: !props.valid
                      ? null
                      : () {
                          if (onConfirm != null) {
                            onConfirm!();
                          }
                        },
                  child: !props.loading
                      ? Text(Strings.buttonConfirmFormal,
                          style: TextStyle(
                            color: props.valid
                                ? Theme.of(context).primaryColor
                                : Color(Colours.greyDisabled),
                          ))
                      : LoadingIndicator(),
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

  const Props({
    required this.valid,
    required this.loading,
    required this.devices,
    required this.onChangePassword,
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
        valid: store.state.authStore.credential != null &&
            store.state.authStore.credential!.value != null &&
            store.state.authStore.credential!.value!.isNotEmpty,
        loading: store.state.settingsStore.loading,
        devices: store.state.settingsStore.devices,
        onChangePassword: (password) {
          store.dispatch(updateCredential(value: password));
        },
      );
}

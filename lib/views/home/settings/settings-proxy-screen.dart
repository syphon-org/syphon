import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/proxy-settings/actions.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-text-input.dart';

class ProxySettingsScreen extends StatelessWidget {
  const ProxySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBarNormal(title: Strings.listItemSettingsProxy),
            body: SingleChildScrollView(
                padding: Dimensions.scrollviewPadding,
                child: Column(
                  children: <Widget>[
                    CardSection(
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => props.onToggleProxy(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              Strings.titleUseProxyServer,
                            ),
                            subtitle: Text(
                              Strings.subtitleUseProxyServer,
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.proxyEnabled,
                              onChanged: (toggle) => props.onToggleProxy(),
                            ),
                          ),
                          Visibility(
                            visible: props.proxyEnabled,
                            child: ListTile(
                              dense: true,
                              onTap: () => props.onEditProxyHost(context),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                Strings.listItemSettingsProxyHost,
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  props.host,
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: props.proxyEnabled,
                            child: ListTile(
                              dense: true,
                              onTap: () => props.onEditProxyPort(context),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                Strings.listItemSettingsProxyPort,
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  props.port,
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: props.proxyEnabled,
                            child: ListTile(
                              onTap: () => props.onToggleProxyAuthentication(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                Strings.titleProxyUseBasicAuthentication,
                              ),
                              subtitle: Text(
                                Strings.subtitleProxyUseBasicAuthentication,
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.proxyAuthenticationEnabled,
                                onChanged: (toggle) => props.onToggleProxyAuthentication(),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: props.proxyEnabled && props.proxyAuthenticationEnabled,
                            child: ListTile(
                              dense: true,
                              onTap: () => props.onEditProxyUsername(context),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                Strings.listItemSettingsProxyUsername,
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  props.username,
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: props.proxyEnabled && props.proxyAuthenticationEnabled,
                            child: ListTile(
                              dense: true,
                              onTap: () => props.onEditProxyPassword(context),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                Strings.listItemSettingsProxyPassword,
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '*' * props.password.length, // hide password
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                )),
          );
        },
      );
}

class _Props extends Equatable {
  final bool proxyEnabled;
  final bool proxyAuthenticationEnabled;

  final String host;
  final String port;
  final String username;
  final String password;

  final Function onToggleProxy;
  final Function onEditProxyHost;
  final Function onEditProxyPort;
  final Function onToggleProxyAuthentication;
  final Function onEditProxyUsername;
  final Function onEditProxyPassword;

  const _Props({
    required this.proxyEnabled,
    required this.proxyAuthenticationEnabled,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.onToggleProxy,
    required this.onEditProxyHost,
    required this.onEditProxyPort,
    required this.onToggleProxyAuthentication,
    required this.onEditProxyUsername,
    required this.onEditProxyPassword,
  });

  @override
  List<Object?> get props => [
        proxyEnabled,
        host,
        port,
        proxyAuthenticationEnabled,
        username,
        password,
        onToggleProxy,
        onEditProxyHost,
        onEditProxyPort,
        onToggleProxyAuthentication,
        onEditProxyUsername,
        onEditProxyPassword,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        proxyEnabled: store.state.settingsStore.proxySettings.enabled,
        host: store.state.settingsStore.proxySettings.host,
        port: store.state.settingsStore.proxySettings.port,
        proxyAuthenticationEnabled: store.state.settingsStore.proxySettings.authenticationEnabled,
        username: store.state.settingsStore.proxySettings.username,
        password: store.state.settingsStore.proxySettings.password,
        onToggleProxy: () async {
          await store.dispatch(toggleProxy());
        },
        onToggleProxyAuthentication: () async {
          await store.dispatch(toggleProxyAuthentication());
        },
        onEditProxyHost: (BuildContext context) async {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: Strings.titleProxyHost,
              content: Strings.contentProxyHost,
              label: Strings.labelProxyHost,
              initialValue: store.state.settingsStore.proxySettings.host,
              inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
              onCancel: () async {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String host) async {
                await store.dispatch(SetProxyHost(host: host));

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
        onEditProxyPort: (BuildContext context) async {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: Strings.titleProxyPort,
              content: Strings.contentProxyPort,
              initialValue: store.state.settingsStore.proxySettings.port,
              label: Strings.labelProxyPort,
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
                FilteringTextInputFormatter.digitsOnly,
              ],
              onCancel: () async {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String port) async {
                await store.dispatch(SetProxyPort(port: port));

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
        onEditProxyUsername: (BuildContext context) async {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: Strings.titleProxyUsername,
              content: Strings.contentProxyUsername,
              label: Strings.labelProxyUsername,
              initialValue: store.state.settingsStore.proxySettings.username,
              inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
              onCancel: () async {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String username) async {
                await store.dispatch(SetProxyUsername(username: username));

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
        onEditProxyPassword: (BuildContext context) async {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: Strings.titleProxyPassword,
              content: Strings.contentProxyPassword,
              label: Strings.labelProxyPassword,
              initialValue: store.state.settingsStore.proxySettings.password,
              inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
              obscureText: true,
              onCancel: () async {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String password) async {
                await store.dispatch(SetProxyPassword(password: password));

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
      );
}

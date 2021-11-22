import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/keys/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/devices-settings/selectors.dart';
import 'package:syphon/store/settings/http-proxy-settings/actions.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm-password.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
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
                          ListTile(
                            enabled: props.proxyEnabled,
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
                          ListTile(
                            enabled: props.proxyEnabled,
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

  final String host;
  final String port;

  final Function onToggleProxy;
  final Function onEditProxyHost;
  final Function onEditProxyPort;

  const _Props({
    required this.proxyEnabled,
    required this.host,
    required this.port,
    required this.onToggleProxy,
    required this.onEditProxyHost,
    required this.onEditProxyPort,
  });

  @override
  List<Object?> get props => [
        proxyEnabled,
        host,
        port,
        onToggleProxy,
        onEditProxyHost,
        onEditProxyPort,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        proxyEnabled: store.state.settingsStore.httpProxySettings.enabled,
        host: store.state.settingsStore.httpProxySettings.host,
        port: store.state.settingsStore.httpProxySettings.port,
        onToggleProxy : () {
          store.dispatch(addInfo(
            message: Strings.alertAppRestartEffect,
            action: 'Dismiss',
          ));

          return store.dispatch(toggleProxy());
        },
        onEditProxyHost: (BuildContext context) {
          return showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: 'Modify Proxy Host',  //TODO i18n
              content: 'The host for your proxy', //TODO i18n
              editingController: TextEditingController(
                text: store.state.settingsStore.httpProxySettings.host,
              ),
              label: 'Hostname', //TODO i18n
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter
              ],
              onCancel: () {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String host) async {
                store.dispatch(SetProxyHost(
                    host: host)
                );

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
        onEditProxyPort: (BuildContext context) {
          return showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: 'Modify Proxy Port', //TODO i18n
              content: 'The port your proxy is listening on', //TODO i18n
              editingController: TextEditingController(
                text: store.state.settingsStore.httpProxySettings.host,
              ),
              label: 'Port',
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
                FilteringTextInputFormatter.digitsOnly,
              ],
              onCancel: () {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String port) async {
                store.dispatch(SetProxyPort(
                    port: port)
                );

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
      );
}

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
        proxyEnabled: store.state.settingsStore.proxySettings.enabled,
        host: store.state.settingsStore.proxySettings.host,
        port: store.state.settingsStore.proxySettings.port,
        onToggleProxy : () async {
          await store.dispatch(toggleProxy());
        },
        onEditProxyHost: (BuildContext context) async {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: Strings.titleProxyHost,
              content: Strings.contentProxyHost,
              editingController: TextEditingController(
                text: store.state.settingsStore.proxySettings.host,
              ),
              label: Strings.labelProxyHost,
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter
              ],
              onCancel: () async {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String host) async {
                await store.dispatch(SetProxyHost(
                    host: host)
                );

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
              editingController: TextEditingController(
                text: store.state.settingsStore.proxySettings.port,
              ),
              label: Strings.labelProxyPort,
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
                FilteringTextInputFormatter.digitsOnly,
              ],
              onCancel: () async {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String port) async {
                await store.dispatch(SetProxyPort(
                    port: port)
                );

                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
      );
}

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:package_info/package_info.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/background/service.dart';
import 'package:syphon/store/user/model.dart';

final bool debug = !kReleaseMode;

class AdvancedView extends StatefulWidget {
  const AdvancedView({Key? key}) : super(key: key);

  @override
  AdvancedViewState createState() => AdvancedViewState();
}

class AdvancedViewState extends State<AdvancedView> {
  AdvancedViewState({Key? key});

  String? version;
  String? buildNumber;

  @override
  void initState() {
    super.initState();
    onMounted();
  }

  @protected
  void onMounted() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    this.setState(() {
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleAdvanced,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
              ),
            ),
            body: SingleChildScrollView(
                child: Column(
              children: <Widget>[
                Visibility(
                  maintainSize: false,
                  visible: debug,
                  child: ListTile(
                    dense: true,
                    onTap: () => props.onStartBackgroundSync(),
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Start Background Service',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug,
                  child: ListTile(
                    dense: true,
                    onTap: () {
                      BackgroundSync.stop();
                      dismissAllNotifications(
                        pluginInstance: globalNotificationPluginInstance,
                      );
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Stop All Services',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug,
                  child: ListTile(
                    dense: true,
                    contentPadding: Dimensions.listPadding,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Fake Dialog"),
                          content: Text("Testing dialog rendering"),
                        ),
                      );
                    },
                    title: Text(
                      'Test Dialog',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug,
                  child: ListTile(
                    dense: true,
                    onTap: () {
                      showMessageNotificationTest(
                        pluginInstance: globalNotificationPluginInstance!,
                      );

                      showBackgroundServiceNotification(
                        notificationId: BackgroundSync.service_id,
                        debugContent:
                            DateFormat('E h:mm ss a').format(DateTime.now()),
                        pluginInstance: globalNotificationPluginInstance!,
                      );
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text('Test Notifcations',
                        style: Theme.of(context).textTheme.subtitle1),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug,
                  child: ListTile(
                    dense: true,
                    contentPadding: Dimensions.listPadding,
                    onTap: () {
                      props.onForceFunction();
                    },
                    title: Text('Force Function',
                        style: Theme.of(context).textTheme.subtitle1),
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Navigator.pushNamed(context, '/licenses');
                  },
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Open Source Licenses',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: props.onToggleSyncing as void Function()?,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Toggle Syncing',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  subtitle: Text(
                    'Toggle syncing with the matrix server',
                    style: TextStyle(
                      color: props.syncing ? Color(Colours.greyDisabled) : null,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      props.syncObserverActive ? 'Syncing' : 'Stopped',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Opacity(
                  opacity: props.syncing ? 0.5 : 1,
                  child: ListTile(
                    dense: true,
                    onTap: props.syncing
                        ? null
                        : props.onManualSync as void Function()?,
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Manual Sync',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: props.syncing
                                ? Color(Colours.greyDisabled)
                                : null,
                          ),
                    ),
                    subtitle: Text(
                      'Perform a forced matrix sync based on last sync timestamp',
                      style: TextStyle(
                        color:
                            props.syncing ? Color(Colours.greyDisabled) : null,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(
                          value: props.syncing ? null : 0),
                    ),
                  ),
                ),
                Opacity(
                  opacity: props.syncing ? 0.5 : 1,
                  child: ListTile(
                    dense: true,
                    onTap: props.syncing
                        ? null
                        : props.onForceFullSync as void Function()?,
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Force Full Sync',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: props.syncing
                                ? Color(Colours.greyDisabled)
                                : null,
                          ),
                    ),
                    subtitle: Text(
                      'Perform a forced full sync of all user data and messages',
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(
                        value: props.syncing ? null : 0,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Version',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  trailing: Text(
                    '$version ($buildNumber)',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            )),
          );
        },
      );
}

class _Props extends Equatable {
  final bool syncing;
  final bool syncObserverActive;
  final String? language;
  final String? lastSince;
  final User currentUser;

  final Function onToggleSyncing;
  final Function onManualSync;
  final Function onForceFullSync;
  final Function onForceFunction;
  final Function onStartBackgroundSync;

  _Props({
    required this.syncing,
    required this.language,
    required this.syncObserverActive,
    required this.currentUser,
    required this.lastSince,
    required this.onManualSync,
    required this.onForceFullSync,
    required this.onToggleSyncing,
    required this.onForceFunction,
    required this.onStartBackgroundSync,
  });

  @override
  List<Object?> get props => [
        syncing,
        lastSince,
        currentUser,
        syncObserverActive,
      ];

  static _Props mapStateToProps(
    Store<AppState> store,
  ) =>
      _Props(
        syncing: store.state.syncStore.syncing,
        language: store.state.settingsStore.language,
        currentUser: store.state.authStore.user,
        lastSince: store.state.syncStore.lastSince,
        syncObserverActive: store.state.syncStore.syncObserver != null &&
            store.state.syncStore.syncObserver!.isActive,
        onToggleSyncing: () {
          final observer = store.state.syncStore.syncObserver;
          if (observer != null && observer.isActive) {
            store.dispatch(stopSyncObserver());
          } else {
            store.dispatch(startSyncObserver());
          }
        },
        onStartBackgroundSync: () async {
          return BackgroundSync.start(
            protocol: store.state.authStore.protocol,
            homeserver: store.state.authStore.user.homeserver,
            accessToken: store.state.authStore.user.accessToken,
            lastSince: store.state.syncStore.lastSince,
          );
        },
        onManualSync: () {
          store.dispatch(fetchSync(since: store.state.syncStore.lastSince));
        },
        onForceFullSync: () {
          store.dispatch(fetchSync(forceFull: true));
        },
        onForceFunction: () {
          store.dispatch(generateOneTimeKeys());
        },
      );
}

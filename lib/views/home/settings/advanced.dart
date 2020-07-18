import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/background/service.dart';
import 'package:syphon/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];
final String protocol = DotEnv().env['PROTOCOL'];

class AdvancedView extends StatelessWidget {
  AdvancedView({Key key}) : super(key: key);

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
                'Advanced',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
              ),
            ),
            body: SingleChildScrollView(
                child: Column(
              children: <Widget>[
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
                  child: ListTile(
                    dense: true,
                    onTap: () {
                      BackgroundSync.start(
                        protocol: protocol,
                        homeserver: props.currentUser.homeserver,
                        accessToken: props.currentUser.accessToken,
                        lastSince: props.lastSince,
                      );
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Start Background Service',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
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
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
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
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
                  child: ListTile(
                    dense: true,
                    onTap: () {
                      showDebugNotification(
                        pluginInstance: globalNotificationPluginInstance,
                      );

                      showBackgroundServiceNotification(
                        notificationId: BackgroundSync.service_id,
                        debugContent:
                            DateFormat('E h:mm ss a').format(DateTime.now()),
                        pluginInstance: globalNotificationPluginInstance,
                      );
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Test Notifcations',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
                  child: ListTile(
                    dense: true,
                    contentPadding: Dimensions.listPadding,
                    onTap: () {
                      props.onForceFunction();
                    },
                    title: Text(
                      'Force Function',
                      style: TextStyle(fontSize: 18.0),
                    ),
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
                  onTap: props.onToggleSyncing,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Toggle Syncing',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  subtitle: Text(
                    'Toggle syncing with the matrix server',
                    style: TextStyle(
                      color: props.loading ? Color(Colours.greyDisabled) : null,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      props.roomsObserverEnabled ? 'Syncing' : 'Stopped',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Opacity(
                  opacity: props.loading ? 0.5 : 1,
                  child: ListTile(
                    dense: true,
                    onTap: props.loading ? null : props.onManualSync,
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Manual Sync',
                      style: TextStyle(
                        fontSize: 18.0,
                        color:
                            props.loading ? Color(Colours.greyDisabled) : null,
                      ),
                    ),
                    subtitle: Text(
                      'Perform a forced matrix sync based on last sync timestamp',
                      style: TextStyle(
                        color:
                            props.loading ? Color(Colours.greyDisabled) : null,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(
                          value: props.loading ? null : 0),
                    ),
                  ),
                ),
                Opacity(
                  opacity: props.loading ? 0.5 : 1,
                  child: ListTile(
                    dense: true,
                    onTap: props.loading ? null : props.onForceFullSync,
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      'Force Full Sync',
                      style: TextStyle(
                        fontSize: 18.0,
                        color:
                            props.loading ? Color(Colours.greyDisabled) : null,
                      ),
                    ),
                    subtitle: Text(
                      'Perform a forced full sync of all user data and messages',
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(
                        value: props.loading ? null : 0,
                      ),
                    ),
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
  final bool loading;
  final bool roomsLoading;
  final bool roomsObserverEnabled;
  final String language;
  final String lastSince;
  final User currentUser;

  final Function onToggleSyncing;
  final Function onManualSync;
  final Function onForceFullSync;
  final Function onForceFunction;

  _Props({
    @required this.syncing,
    @required this.loading,
    @required this.roomsLoading,
    @required this.language,
    @required this.roomsObserverEnabled,
    @required this.currentUser,
    @required this.lastSince,
    @required this.onManualSync,
    @required this.onForceFullSync,
    @required this.onToggleSyncing,
    @required this.onForceFunction,
  });

  @override
  List<Object> get props => [
        syncing,
        loading,
        lastSince,
        currentUser,
        roomsLoading,
        roomsObserverEnabled,
      ];

  static _Props mapStateToProps(
    Store<AppState> store,
  ) =>
      _Props(
        syncing: store.state.syncStore.syncing,
        loading: store.state.syncStore.syncing || store.state.syncStore.loading,
        roomsLoading: store.state.syncStore.loading,
        language: store.state.settingsStore.language,
        currentUser: store.state.authStore.user,
        lastSince: store.state.syncStore.lastSince,
        roomsObserverEnabled: store.state.syncStore.syncObserver != null &&
            store.state.syncStore.syncObserver.isActive,
        onToggleSyncing: () {
          final observer = store.state.syncStore.syncObserver;
          if (observer != null && observer.isActive) {
            store.dispatch(stopSyncObserver());
          } else {
            store.dispatch(startSyncObserver());
          }
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

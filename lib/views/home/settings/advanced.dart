import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/notifications.dart';
import 'package:Tether/store/service.dart';
import 'package:Tether/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];
final String protocol = DotEnv().env['PROTOCOL'];

class AdvancedScreen extends StatelessWidget {
  AdvancedScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          final contentPadding =
              EdgeInsets.symmetric(horizontal: 24, vertical: 8);

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
            body: Container(
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
                    contentPadding: contentPadding,
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
                    contentPadding: contentPadding,
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
                    contentPadding: contentPadding,
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
                        notificationId: tether_service_id,
                        debugContent:
                            DateFormat('E h:mm ss a').format(DateTime.now()),
                        pluginInstance: globalNotificationPluginInstance,
                      );
                    },
                    contentPadding: contentPadding,
                    title: Text(
                      'Test Notifcations',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: props.onToggleSyncing,
                  contentPadding: contentPadding,
                  title: Text(
                    'Toggle Syncing',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  subtitle: Text(
                    'Toggle syncing with the matrix server',
                    style: TextStyle(
                      color: props.loading ? Color(DISABLED_GREY) : null,
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
                    contentPadding: contentPadding,
                    title: Text(
                      'Manual Sync',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: props.loading ? Color(DISABLED_GREY) : null,
                      ),
                    ),
                    subtitle: Text(
                      'Perform a forced matrix sync based on last sync timestamp',
                      style: TextStyle(
                        color: props.loading ? Color(DISABLED_GREY) : null,
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
                    contentPadding: contentPadding,
                    title: Text(
                      'Force Full Sync',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: props.loading ? Color(DISABLED_GREY) : null,
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

  _Props({
    @required this.syncing,
    @required this.loading,
    @required this.roomsLoading,
    @required this.language,
    @required this.onManualSync,
    @required this.onForceFullSync,
    @required this.onToggleSyncing,
    @required this.roomsObserverEnabled,
    @required this.currentUser,
    @required this.lastSince,
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

  /* effectively mapStateToProps, but includes functions */
  static _Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      _Props(
        syncing: store.state.roomStore.syncing,
        loading: store.state.roomStore.syncing || store.state.roomStore.loading,
        roomsLoading: store.state.roomStore.loading,
        language: store.state.settingsStore.language,
        currentUser: store.state.userStore.user,
        lastSince: store.state.roomStore.lastSince,
        roomsObserverEnabled: store.state.roomStore.roomObserver.isActive,
        onToggleSyncing: () {
          final observer = store.state.roomStore.roomObserver;
          if (observer != null && observer.isActive) {
            store.dispatch(stopRoomsObserver());
          } else {
            store.dispatch(startRoomsObserver());
          }
        },
        onManualSync: () {
          if (store.state.roomStore.lastSince != null) {
            store.dispatch(fetchSync(since: store.state.roomStore.lastSince));
          }
        },
        onForceFullSync: () {
          store.dispatch(fetchSync(forceFull: true));
        },
      );
}

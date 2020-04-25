import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/store/rooms/service.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class AdvancedScreen extends StatelessWidget {
  AdvancedScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
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
                      // Dispatch Background Sync
                      if (roomObserverIsolate != null) {
                        stopRoomObserverService();
                      } else {
                        startRoomObserverService();
                      }
                    },
                    contentPadding: contentPadding,
                    title: Text(
                      roomObserverIsolate != null
                          ? 'Kill Isolate'
                          : 'Start Isolate',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
                  child: ListTile(
                    dense: true,
                    onTap: () async {
                      await sendServiceAction('bye bye');
                      print('action completed');
                    },
                    contentPadding: contentPadding,
                    title: Text(
                      'Toggle Isolate Timer',
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
                      style: TextStyle(fontSize: 18.0),
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
                  // opacity: props.loading ? 0.5 : 1,
                  opacity: 0.5,
                  child: ListTile(
                    dense: true,
                    onTap: null,
                    // onTap: props.loading ? null : props.onForceFullSync,
                    contentPadding: contentPadding,
                    title: Text(
                      'Force Full Sync',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: props.loading ? Colors.grey : Colors.white,
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

class Props {
  final bool syncing;
  final bool loading;
  final bool roomsLoading;
  final bool roomsObserverEnabled;
  final String language;
  final Function onToggleSyncing;
  final Function onManualSync;
  final Function onForceFullSync;

  Props({
    @required this.syncing,
    @required this.loading,
    @required this.roomsLoading,
    @required this.language,
    @required this.onManualSync,
    @required this.onForceFullSync,
    @required this.onToggleSyncing,
    @required this.roomsObserverEnabled,
  });

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
          syncing: store.state.roomStore.syncing,
          loading:
              store.state.roomStore.syncing || store.state.roomStore.loading,
          roomsLoading: store.state.roomStore.loading,
          language: store.state.settingsStore.language,
          roomsObserverEnabled: store.state.roomStore.roomObserver.isActive,
          onToggleSyncing: () {
            final observer = store.state.roomStore.roomObserver;
            if (observer != null && observer.isActive) {
              store.dispatch(stopRoomsObserver());
            } else {
              store.dispatch(startRoomsObserver());
            }
          },
          onForceFullSync: () {
            store.dispatch(fetchSync());
          },
          onManualSync: () {
            if (store.state.roomStore.lastSince != null) {
              store.dispatch(fetchSync(since: store.state.roomStore.lastSince));
            }
          });

  @override
  int get hashCode => syncing.hashCode ^ roomsLoading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          syncing == other.syncing &&
          loading == other.loading &&
          roomsObserverEnabled == other.roomsObserverEnabled &&
          roomsLoading == other.roomsLoading;
}

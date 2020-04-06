import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/actions.dart';
import 'package:Tether/domain/settings/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class NotificationSettings extends StatelessWidget {
  NotificationSettings({Key key}) : super(key: key);

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
                'Notifications',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
              ),
            ),
            body: Container(
                child: Column(
              children: <Widget>[
                ListTile(
                  dense: true,
                  onTap: props.onToggleSyncing,
                  contentPadding: contentPadding,
                  title: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: ToggleButtons(),
                  ),
                )
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

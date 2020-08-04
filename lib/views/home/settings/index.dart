// Flutter imports:
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
import './widgets/profile-preview.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key key}) : super(key: key);

  Widget buildToggledSubtitle({bool value}) {
    return Text(
      value ? 'On' : 'Off',
      style: TextStyle(fontSize: 14.0),
    );
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
                onPressed: props.authLoading
                    ? null
                    : () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleSettings,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: SingleChildScrollView(
              physics: props.authLoading
                  ? const NeverScrollableScrollPhysics()
                  : null,
              // Use a container of the same height and width
              // to flex dynamically but within a single child scroll
              child: IgnorePointer(
                ignoring: props.authLoading,
                child: Container(
                  child: Column(
                    children: <Widget>[
                      InkWell(
                        child: Container(
                          padding: Dimensions.heroPadding,
                          child: ProfilePreview(),
                        ),
                        onTap: props.authLoading
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/profile');
                              },
                      ),
                      Container(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              onTap: props.authLoading ? null : () {},
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.chat,
                                    size: 28,
                                  )),
                              title: Text(
                                'SMS and MMS',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              subtitle: buildToggledSubtitle(value: false),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                          context, '/notifications');
                                    },
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.notifications,
                                    size: 28,
                                  )),
                              title: Text(
                                'Notifications',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              subtitle: buildToggledSubtitle(
                                value: props.notificationsEnabled,
                              ),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                          context, '/chat-preferences');
                                    },
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.only(
                                    top: 4,
                                    left: 4,
                                    bottom: 4,
                                    right: 4,
                                  ),
                                  child: Icon(
                                    Icons.photo_filter,
                                    size: 28,
                                  )),
                              title: Text(
                                'Chats And Media',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/privacy');
                                    },
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.lock,
                                    size: 28,
                                  )),
                              title: Text(
                                'Security & Privacy',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              subtitle: Text(
                                'Screen Lock Off, Registration Lock Off',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/theming');
                                    },
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.brightness_medium,
                                    size: 28,
                                  )),
                              title: Text(
                                'Theming',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/devices');
                                    },
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.phone_android,
                                    size: 28,
                                  )),
                              title: Text(
                                'Devices',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/advanced');
                                    },
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.code,
                                    size: 28,
                                  )),
                              title: Text(
                                'Advanced',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            ListTile(
                              onTap: props.authLoading
                                  ? null
                                  : () => props.onLogoutUser(),
                              contentPadding: Dimensions.listPadding,
                              leading: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.exit_to_app,
                                    size: 28,
                                  )),
                              title: Text(
                                'Logout',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Visibility(
                                visible: props.authLoading,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor,
                                    ),
                                    value: null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool authLoading;
  final bool notificationsEnabled;

  final Function onLogoutUser;

  _Props({
    @required this.loading,
    @required this.authLoading,
    @required this.notificationsEnabled,
    @required this.onLogoutUser,
  });

  @override
  List<Object> get props => [
        loading,
        authLoading,
        notificationsEnabled,
      ];

  static _Props mapStateToProps(
    Store<AppState> store,
  ) =>
      _Props(
        loading: store.state.roomStore.loading,
        authLoading: store.state.authStore.loading,
        notificationsEnabled: store.state.settingsStore.notificationsEnabled,
        onLogoutUser: () {
          store.dispatch(logoutUser());
        },
      );
}

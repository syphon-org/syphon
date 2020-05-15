import 'package:Tether/store/index.dart';
import 'package:Tether/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import './widgets/profile-preview.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key key, this.title}) : super(key: key);

  final String title;

  Widget buildToggledSubtitle({bool value}) {
    return Text(
      value ? 'On' : 'Off',
      style: TextStyle(fontSize: 14.0),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

          // TODO: set max contstraints
          final headerPadding = EdgeInsets.symmetric(
            horizontal: width * 0.0575,
            vertical: height * 0.04,
          );

          // Static horizontal: 16, vertical: 8
          final contentPadding = EdgeInsets.symmetric(
            horizontal: width * 0.08,
            vertical: height * 0.005,
          );

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: SingleChildScrollView(
              // Use a container of the same height and width
              // to flex dynamically but within a single child scroll
              child: Container(
                child: Column(
                  children: <Widget>[
                    InkWell(
                      child: Container(
                        padding: headerPadding,
                        child: ProfilePreview(),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    Container(
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            onTap: () {},
                            contentPadding: contentPadding,
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
                            onTap: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                            contentPadding: contentPadding,
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
                            onTap: () {
                              Navigator.pushNamed(context, '/chat-preferences');
                            },
                            contentPadding: contentPadding,
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
                            onTap: () {
                              Navigator.pushNamed(context, '/privacy');
                            },
                            contentPadding: contentPadding,
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
                            onTap: () {
                              Navigator.pushNamed(context, '/theming');
                            },
                            contentPadding: contentPadding,
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
                            onTap: () {
                              Navigator.pushNamed(context, '/devices');
                            },
                            contentPadding: contentPadding,
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
                            onTap: () {},
                            contentPadding: contentPadding,
                            leading: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.data_usage,
                                  size: 28,
                                )),
                            title: Text(
                              'Storage',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, '/advanced');
                            },
                            contentPadding: contentPadding,
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
                            onTap: () => props.onLogoutUser(),
                            contentPadding: contentPadding,
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool notificationsEnabled;

  final Function onLogoutUser;

  _Props({
    @required this.loading,
    @required this.notificationsEnabled,
    @required this.onLogoutUser,
  });

  @override
  List<Object> get props => [
        loading,
        notificationsEnabled,
      ];

  /* effectively mapStateToProps, but includes functions */
  static _Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      _Props(
        loading: store.state.roomStore.syncing || store.state.roomStore.loading,
        notificationsEnabled: store.state.settingsStore.notificationsEnabled,
        onLogoutUser: () {
          store.dispatch(logoutUser());
        },
      );
}

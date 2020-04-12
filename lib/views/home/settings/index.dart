import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/actions.dart';
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
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Store<AppState>>(
        distinct: true,
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
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
                              value: store
                                  .state.settingsStore.notificationsEnabled,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: contentPadding,
                            leading: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.lock,
                                  size: 28,
                                )),
                            title: Text(
                              'Privacy',
                              style: TextStyle(fontSize: 18.0),
                            ),
                            subtitle: Text(
                              'Screen Lock Off, Registration Lock Off',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, '/customization');
                            },
                            contentPadding: contentPadding,
                            leading: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.brightness_medium,
                                  size: 28,
                                )),
                            title: Text(
                              'Customization',
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
                            onTap: () {},
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
                            onTap: () {
                              store.dispatch(logoutUser());
                            },
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

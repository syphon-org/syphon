import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/views/navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import './profile-preview.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key key, this.title}) : super(key: key);

  final String title;

  Widget buildToggledSubtitle({String option}) {
    return Text(
      option == null ? 'Off' : 'On',
      style: TextStyle(fontSize: 14.0),
    );
  }

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Store<AppState>>(
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w100)),
            ),
            body: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  children: <Widget>[
                    ProfilePreview(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            onTap: () {},
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                            subtitle: buildToggledSubtitle(),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                            subtitle: buildToggledSubtitle(),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                              Navigator.pushNamed(context, '/appearance');
                            },
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.brightness_medium,
                                  size: 28,
                                )),
                            title: Text(
                              'Appearance',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                )),
          );
        },
      );
}

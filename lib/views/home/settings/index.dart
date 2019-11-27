import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import './profile-preview.dart';

const List<Map> options = [
  {"title": 'Profile'},
  {
    "title": 'Notifications',
    "subtitle": "On",
  },
  {
    "title": 'Privacy',
    "subtitle": "Configuration and Checklist",
  },
  {
    "title": 'Chats and Data',
    "subtitle": "Manage your matrix data",
  },
  {
    "title": 'Appearance',
    "subtitle": "",
  },
  {
    "title": 'Devices',
    "subtitle": "",
  },
  {
    "title": 'Advanced',
    "subtitle": "",
  },
  {
    "title": 'Logout',
    "subtitle": "",
  },
];

const List<IconData> optionIcons = [
  null,
  Icons.notifications,
  Icons.security,
  Icons.chat_bubble,
  Icons.brightness_medium,
  Icons.phone_android,
  Icons.code,
  Icons.exit_to_app,
  null,
  null,
  null,
];

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key key, this.title}) : super(key: key);

  final String title;

  Widget buildOptions({List<Map> options, BuildContext context}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      scrollDirection: Axis.vertical,
      itemCount: options.length,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return TouchableOpacity(
              activeOpacity: 0.2,
              onTap: () {
                print('navigate to profile');
              },
              child: ProfilePreview());
        }

        return ListTile(
          // contentPadding: EdgeInsets.symmetric(vertical: 8),
          onTap: () {
            print('STUB ${options[index]['title']}');
          },
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
              padding: EdgeInsets.all(4),
              child: Icon(optionIcons[index], size: 28)),
          title: Text(
            options[index]['title'].toString(),
            style: TextStyle(fontSize: 18.0),
          ),
          subtitle: options[index]['subtitle'].length != 0
              ? Text(
                  options[index]['subtitle'].toString(),
                  style: TextStyle(fontSize: 14.0),
                )
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
      ),
      body: Align(child: buildOptions(options: options, context: context)),
    );
  }
}

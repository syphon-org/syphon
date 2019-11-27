import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';

import 'package:Tether/domain/chat/selectors.dart';

import 'package:Tether/domain/chat/actions.dart';

const List<Map> options = [
  {"title": 'Profile', "description": "On", "icon": 'testing'},
  {"title": 'Privacy', "description": "On", "icon": 'testing'},
  {"title": 'Appearance', "description": "On", "icon": 'testing'},
  {"title": 'Notifications', "description": "On", "icon": 'testing'},
  {"title": 'Chats and Data', "description": "On", "icon": 'testing'},
  {"title": 'Devices', "description": "On", "icon": 'testing'},
  {"title": 'Advanced', "description": "On", "icon": 'testing'},
  {"title": 'Logout', "description": "On", "icon": 'testing'},
  {"title": 'Delete This User', "description": "On", "icon": 'testing'},
];

class ProfilePreview extends StatelessWidget {
  ProfilePreview({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              height: 56,
              width: 56,
              margin: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Text(
                  'TE',
                  style: TextStyle(color: Colors.white, fontSize: 20.0),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Taylor Ereio',
                  style: TextStyle(fontSize: 20.0),
                ),
                Text(
                  '+14702578193',
                  style: TextStyle(fontSize: 14.0),
                ),
              ],
            )
          ],
        ));
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/store/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:Tether/store/user/selectors.dart';

class DialogColor extends StatelessWidget {
  DialogColor({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
          child: Row(
        children: <Widget>[
          Container(
            height: 56,
            width: 56,
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Text(
                'Primary Color',
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

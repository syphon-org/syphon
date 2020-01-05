import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:Tether/domain/user/selectors.dart';

class ProfilePreview extends StatelessWidget {
  ProfilePreview({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Store<AppState>>(
        rebuildOnChange: false,
        converter: (Store<AppState> store) => store,
        builder: (context, store) {
          return Container(
              child: TouchableOpacity(
                  activeOpacity: 0.2,
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: Container(
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
                                displayInitials(store.state),
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20.0),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                shortname(store.state),
                                style: TextStyle(fontSize: 20.0),
                              ),
                              Text(
                                store.state.userStore.user.userId,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          )
                        ],
                      ))));
        });
  }
}

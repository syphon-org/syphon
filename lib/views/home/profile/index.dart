import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/selectors.dart';

import 'package:Tether/global/dimensions.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/behaviors.dart';

class Profile extends StatelessWidget {
  Profile({Key key}) : super(key: key);

  final String title = 'Set up Your Profile';

  Function onChangeDisplayName(Store<AppState> store) {
    return () {
      print("On Change Display Name Stub");
    };
  }

  Function onChangeAvatar(Store<AppState> store) {
    return () {
      print("On Change Avatar Stub");
    };
  }

  Function onSaveUser(Store<AppState> store) {
    return () {
      print("On Change Avatar Stub");
    };
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = 800; // testing only
    AppBar appBar = AppBar(
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
    );

    return StoreConnector<AppState, Store<AppState>>(
      converter: (Store<AppState> store) => store,
      builder: (context, store) => Scaffold(
        appBar: appBar,
        body: ScrollConfiguration(
          behavior: DefaultScrollBehavior(),
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxHeight: height),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: width * 0.25,
                              height: width * 0.25,
                              margin: const EdgeInsets.all(16.0),
                              child: TouchableOpacity(
                                activeOpacity: 0.2,
                                onTap: onChangeAvatar(store),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Text(
                                    displayInitials(store.state.userStore.user),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 32.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: Container(
                      // TODO: have a default max expension for certain widgets
                      constraints: BoxConstraints(
                        minWidth: 125,
                        minHeight: 200,
                        maxHeight: 400,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: width * 0.7,
                                      height: DEFAULT_INPUT_HEIGHT,
                                      margin: const EdgeInsets.all(8.0),
                                      constraints: BoxConstraints(
                                          minWidth: 200,
                                          maxWidth: 400,
                                          minHeight: 45),
                                      child: TextField(
                                        onChanged: (name) {
                                          print('On Change Display Name Stub');
                                        },
                                        controller:
                                            TextEditingController.fromValue(
                                          TextEditingValue(
                                            text: displayName(store.state),
                                            selection: TextSelection(
                                                baseOffset: store
                                                    .state
                                                    .userStore
                                                    .homeserver
                                                    .length,
                                                extentOffset: store
                                                    .state
                                                    .userStore
                                                    .homeserver
                                                    .length),
                                          ),
                                        ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Display Name',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: width * 0.7,
                                      height: DEFAULT_INPUT_HEIGHT,
                                      margin: const EdgeInsets.all(8.0),
                                      constraints: BoxConstraints(
                                          minWidth: 200,
                                          maxWidth: 400,
                                          minHeight: 45),
                                      child: TextField(
                                        onChanged: (name) {
                                          print('On Change User Id Stub');
                                        },
                                        controller:
                                            TextEditingController.fromValue(
                                          TextEditingValue(
                                            text: store
                                                .state.userStore.user.userId,
                                            selection: TextSelection(
                                                baseOffset: store
                                                    .state
                                                    .userStore
                                                    .user
                                                    .userId
                                                    .length,
                                                extentOffset: store
                                                    .state
                                                    .userStore
                                                    .user
                                                    .userId
                                                    .length),
                                          ),
                                        ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'User ID',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: width * 0.7,
                                      height: DEFAULT_BUTTON_HEIGHT,
                                      margin: const EdgeInsets.all(10.0),
                                      constraints: BoxConstraints(
                                          minWidth: 200,
                                          maxWidth: 400,
                                          minHeight: 45,
                                          maxHeight: 65),
                                      child: FlatButton(
                                        onPressed: () {},
                                        color: Theme.of(context).primaryColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(
                                                    30.0)),
                                        child: Text(
                                          'save',
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: DEFAULT_INPUT_HEIGHT,
                                      margin: const EdgeInsets.all(10.0),
                                      constraints: BoxConstraints(
                                          minWidth: 200, minHeight: 45),
                                      child: Visibility(
                                        child: TouchableOpacity(
                                          activeOpacity: 0.4,
                                          onTap: () => Navigator.pop(context),
                                          child: Text(
                                            'Quit editing',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w100,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

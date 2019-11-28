import 'package:Tether/domain/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/chat/selectors.dart';
import 'package:Tether/domain/user/model.dart';
import 'package:Tether/domain/settings/actions.dart';

// Styling
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/behaviors.dart';

// Assets
import 'package:Tether/global/assets.dart';

class Login extends StatelessWidget {
  Login({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    /* 
     * TODO: find a more explicit way to style with flex
     * Should be able to specify flex as a ratio of screen coverage without
     * stretching elements, a mix of container and expanded
    */
    return Scaffold(
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
            // Use a container of the same height and width
            // to flex dynamically but within a single child scroll
            child: Container(
                height: height,
                width: width,
                child: StoreConnector<AppState, dynamic>(
                    converter: (store) =>
                        () => store.dispatch(incrementTheme()),
                    builder: (context, onIncrementTheme) {
                      return Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Spacer(flex: 8),
                          TouchableOpacity(
                            onTap: () {
                              onIncrementTheme();
                            },
                            child: const Image(
                              width: 150,
                              height: 150,
                              image: AssetImage(TETHER_ICON_PNG),
                            ),
                          ),
                          Spacer(flex: 4),
                          Text(
                            'Take back the chat',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.display1,
                          ),
                          Spacer(flex: 4),
                          StoreConnector<AppState, Store<AppState>>(
                              converter: (Store<AppState> store) => store,
                              builder: (context, store) {
                                return Container(
                                  width: width * 0.7,
                                  height: DEFAULT_INPUT_HEIGHT,
                                  margin: const EdgeInsets.all(10.0),
                                  constraints: BoxConstraints(
                                      minWidth: 200,
                                      maxWidth: 400,
                                      minHeight: 45),
                                  child: TextField(
                                    onChanged: (username) {
                                      // If user enters full username, make sure to set homeserver
                                      if (username.contains(':')) {
                                        final alias = username.split(':');
                                        store.dispatch(
                                            setUsername(username: alias[0]));
                                        store.dispatch(setHomeserver(
                                            homeserver: alias[1]));
                                      } else {
                                        store.dispatch(
                                            setUsername(username: username));
                                      }
                                    },
                                    decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                            icon: Icon(Icons.help_outline),
                                            tooltip:
                                                'Select your usernames homeserver',
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/search_home',
                                              );
                                            }),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0)),
                                        hintText: store.state.userStore
                                                    .homeserver.length !=
                                                0
                                            ? '@username:${store.state.userStore.homeserver}'
                                            : '@username:tether.org',
                                        labelText: 'username'),
                                  ),
                                );
                              }),
                          StoreConnector<AppState, Store<AppState>>(
                              converter: (Store<AppState> store) => store,
                              builder: (context, store) {
                                return Container(
                                  width: width * 0.7,
                                  height: DEFAULT_INPUT_HEIGHT,
                                  margin: const EdgeInsets.all(10.0),
                                  constraints: BoxConstraints(
                                      minWidth: 200,
                                      maxWidth: 400,
                                      minHeight: 45),
                                  child: TextField(
                                    onChanged: (password) {
                                      store.dispatch(
                                          setPassword(password: password));
                                    },
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0)),
                                      labelText: 'password',
                                    ),
                                  ),
                                );
                              }),
                          Spacer(flex: 1),
                          StoreConnector<AppState, Store<AppState>>(
                            converter: (Store<AppState> store) => store,
                            builder: (context, store) {
                              return Container(
                                width: width * 0.7,
                                height: DEFAULT_BUTTON_HEIGHT,
                                margin: const EdgeInsets.all(10.0),
                                constraints: BoxConstraints(
                                    minWidth: 200,
                                    maxWidth: 400,
                                    minHeight: 45),
                                child: FlatButton(
                                  disabledColor: Colors.grey,
                                  disabledTextColor: Colors.grey[300],
                                  onPressed: () {
                                    store.dispatch(loginUser());
                                  },
                                  color: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(30.0)),
                                  child: const Text('Login',
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white)),
                                ),
                              );
                            },
                          ),
                          Spacer(flex: 1),
                          Container(
                              height: DEFAULT_INPUT_HEIGHT,
                              margin: const EdgeInsets.all(10.0),
                              constraints:
                                  BoxConstraints(minWidth: 200, minHeight: 45),
                              child: TouchableOpacity(
                                  activeOpacity: 0.4,
                                  onTap: () => Navigator.pushNamed(
                                        context,
                                        '/signup',
                                      ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Don\'t have an username?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w100,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text('Create one',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w100,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              decoration:
                                                  TextDecoration.underline,
                                            )),
                                      ),
                                    ],
                                  ))),
                          Spacer(flex: 1),
                        ],
                      );
                    }))),
      ),
    );
  }
}

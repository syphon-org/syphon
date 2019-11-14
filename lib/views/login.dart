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

// Assets
import 'package:Tether/global/assets.dart';

class LoginScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class LoginScreen extends StatelessWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double DEFAULT_INPUT_HEIGHT = 52;
    double DEFAULT_BUTTON_HEIGHT = 48;

    /* 
     * TODO: find a more explicit way to style with flex
     * Should be able to specify flex as a ratio of screen coverage without
     * stretching elements, a mix of container and expanded
    */
    return Scaffold(
      body: ScrollConfiguration(
        behavior: LoginScrollBehavior(),
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
                          StoreConnector<AppState, AppState>(
                              converter: (Store<AppState> store) => store.state,
                              builder: (context, state) {
                                return Container(
                                  width: width * 0.7,
                                  height: DEFAULT_INPUT_HEIGHT,
                                  margin: const EdgeInsets.all(10.0),
                                  constraints: BoxConstraints(
                                      minWidth: 200,
                                      maxWidth: 400,
                                      minHeight: 45),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      suffixIcon:
                                          //  Ink(
                                          //     width: 5,
                                          //     height: 5,
                                          //     decoration: BoxDecoration(
                                          //       border: Border.all(
                                          //           color: Colors.cyan, width: 2.0),
                                          //       shape: BoxShape.circle,
                                          //     ),
                                          //     child:
                                          IconButton(
                                              icon: Icon(Icons.help_outline),
                                              tooltip:
                                                  'Select your usernames homeserver',
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/search_home',
                                                );
                                              }),
                                      // ),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0)),
                                      labelText: 'username@' +
                                          state.userStore.homeserver,
                                    ),
                                  ),
                                );
                              }),
                          StoreConnector<AppState, int>(
                              converter: (Store<AppState> store) =>
                                  counter(store.state),
                              builder: (context, count) {
                                return Container(
                                  width: width * 0.7,
                                  height: DEFAULT_INPUT_HEIGHT,
                                  margin: const EdgeInsets.all(10.0),
                                  constraints: BoxConstraints(
                                      minWidth: 200,
                                      maxWidth: 400,
                                      minHeight: 45),
                                  child: TextField(
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
                          StoreConnector<AppState, UserStore>(
                            converter: (Store<AppState> store) =>
                                store.state.userStore,
                            builder: (context, userStore) {
                              return Container(
                                width: width * 0.7,
                                height: DEFAULT_BUTTON_HEIGHT,
                                margin: const EdgeInsets.all(10.0),
                                constraints: BoxConstraints(
                                    minWidth: 200,
                                    maxWidth: 400,
                                    minHeight: 45),
                                child: FlatButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/home');
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

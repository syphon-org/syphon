import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/chat/selectors.dart';
import 'package:Tether/domain/user/model.dart';
import 'package:Tether/domain/settings/actions.dart';

// Styling
import 'package:touchable_opacity/touchable_opacity.dart';

// TODO: do you want these?
// const Image(
//   image: NetworkImage(
//       'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
// ),

// Text(
//   'Welcome!',
//   style: Theme.of(context).textTheme.display2,
// ),

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

    return Scaffold(
      body: ScrollConfiguration(
        behavior: LoginScrollBehavior(),
        child: SingleChildScrollView(
            child: Center(
                child: StoreConnector<AppState, dynamic>(
                    converter: (store) =>
                        () => store.dispatch(incrementTheme()),
                    builder: (context, onIncrementTheme) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: height * 0.05),
                          TouchableOpacity(
                            onTap: () {
                              onIncrementTheme();
                            },
                            child: const Image(
                              width: 250,
                              height: 250,
                              image: AssetImage(
                                  'assets/icons/noun_polygon_teal.png'),
                            ),
                          ),
                          SizedBox(height: height * 0.025),
                          Text(
                            'Take back the chat',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.display1,
                          ),
                          SizedBox(height: height * 0.1),
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
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0)),
                                      labelText: 'Username',
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
                                      labelText: 'Password',
                                    ),
                                  ),
                                );
                              }),
                          SizedBox(height: height * 0.05),
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
                                        'Don\'t have an alias yet?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w100,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text('Create an alias',
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
                                  )))
                        ],
                      );
                    }))),
      ),
    );
  }
}

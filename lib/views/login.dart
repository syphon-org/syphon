import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/domain/user/selectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/settings/actions.dart';

// Styling
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/behaviors.dart';

// Assets
import 'package:Tether/global/assets.dart';

class Login extends StatefulWidget {
  final Store<AppState> store;
  const Login({Key key, this.store}) : super(key: key);

  @override
  LoginState createState() => LoginState(store: this.store);
}

class LoginState extends State<Login> {
  final GlobalKey<ScaffoldState> loginScaffold = GlobalKey<ScaffoldState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocus = FocusNode();

  final Store<AppState> store;

  LoginState({Key key, this.store});

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @protected
  void onMounted() {
    // Init alerts listener
    store.state.alertsStore.onAlertsChanged.listen((alert) {
      var color;

      switch (alert.type) {
        case 'warning':
          color = Colors.red;
          break;
        case 'error':
          color = Colors.red;
          break;
        case 'info':
        default:
          color = Colors.grey;
      }

      loginScaffold.currentState.showSnackBar(SnackBar(
        backgroundColor: color,
        content: Text(alert.message),
        duration: alert.duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            loginScaffold.currentState.removeCurrentSnackBar();
          },
        ),
      ));
    });
  }

  void handleSubmitted(String value) {
    FocusScope.of(context).requestFocus(passwordFocus);
  }

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
      key: loginScaffold,
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
          // Use a container of the same height and width
          // to flex dynamically but within a single child scroll
          child: Container(
            height: height,
            width: width,
            constraints: BoxConstraints(
              maxHeight: 1024,
              maxWidth: 512,
            ),
            child: StoreConnector<AppState, Store<AppState>>(
              converter: (store) => store,
              builder: (context, store) => Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    flex: 3,
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TouchableOpacity(
                          onTap: () {
                            store.dispatch(
                              incrementTheme(),
                            );
                          },
                          child: const Image(
                            width: 150,
                            height: 150,
                            image: AssetImage(TETHER_ICON_PNG),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Take back the chat',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ]),
                  ),
                  Flexible(
                    flex: 2,
                    fit: FlexFit.loose,
                    child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: width * 0.725,
                            height: DEFAULT_INPUT_HEIGHT,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 200,
                              maxWidth: 400,
                            ),
                            child: TextField(
                              controller: usernameController,
                              onSubmitted: handleSubmitted,
                              onChanged: (username) {
                                // Trim value for UI
                                usernameController.value = TextEditingValue(
                                  text: username.trim(),
                                  selection: TextSelection.fromPosition(
                                    TextPosition(
                                      offset: username.trim().length,
                                    ),
                                  ),
                                );
                                // If user enters full username, make sure to set homeserver
                                if (username.contains(':')) {
                                  final alias = username.trim().split(':');
                                  store.dispatch(setUsername(
                                    username: alias[0],
                                  ));
                                  store.dispatch(setHomeserver(
                                    homeserver: alias[1],
                                  ));
                                } else {
                                  store.dispatch(setUsername(
                                    username: username.trim(),
                                  ));
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                  left: 20,
                                  top: 32,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.help_outline),
                                  tooltip: 'Select your usernames homeserver',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/search_home',
                                    );
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28.0),
                                ),
                                hintText: store.state.userStore.homeserver
                                            .length !=
                                        0
                                    ? 'username:${store.state.userStore.homeserver}'
                                    : 'username:tether.org',
                                labelText: 'username',
                              ),
                            ),
                          ),
                          Container(
                            width: width * 0.725,
                            height: DEFAULT_INPUT_HEIGHT,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 200,
                              maxWidth: 400,
                            ),
                            child: TextField(
                              focusNode: passwordFocus,
                              onChanged: (password) {
                                store.dispatch(setPassword(password: password));
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                  left: 20,
                                  top: 32,
                                  bottom: 32,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                labelText: 'password',
                              ),
                            ),
                          ),
                        ]),
                  ),
                  Container(
                    width: width * 0.725,
                    height: DEFAULT_BUTTON_HEIGHT,
                    margin: const EdgeInsets.only(
                      top: 24,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 200,
                      maxWidth: 400,
                    ),
                    child: FlatButton(
                      disabledColor: Colors.grey,
                      disabledTextColor: Colors.grey[300],
                      onPressed: isLoginAttemptable(store.state)
                          ? () {
                              store.dispatch(loginUser());
                            }
                          : null,
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: isAuthLoading(store.state)
                          ? Container(
                              constraints: BoxConstraints(
                                maxHeight: 28,
                                maxWidth: 28,
                              ),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey,
                                ),
                              ),
                            )
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  Container(
                    height: DEFAULT_INPUT_HEIGHT,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 24,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 200,
                      minHeight: 45,
                    ),
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
                            child: Text(
                              'Create one',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w100,
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
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

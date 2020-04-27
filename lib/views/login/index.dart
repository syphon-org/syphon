import 'package:Tether/store/user/actions.dart';
import 'package:Tether/store/user/selectors.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/global/themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';

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

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void handleSubmitted(String value) {
    FocusScope.of(context).requestFocus(passwordFocus);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final double defaultWidgetScaling = width * 0.725;

    return Scaffold(
      key: loginScaffold,
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
          // Use a container of the same height and width
          // to flex dynamically but within a single child scroll
          child: StoreConnector<AppState, Store<AppState>>(
            converter: (store) => store,
            builder: (context, store) => Container(
              height: height,
              constraints: BoxConstraints(
                maxHeight: Dimensions.widgetHeightMax,
              ),
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    flex: 4,
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
                          child: Image(
                            width: width * 0.35,
                            height: width * 0.35,
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
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              LOGIN_TITLE,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                        ]),
                  ),
                  Flexible(
                    flex: 3,
                    fit: FlexFit.loose,
                    child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: defaultWidgetScaling,
                            height: Dimensions.inputHeight,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              minWidth: Dimensions.inputWidthMin,
                              maxWidth: Dimensions.inputWidthMax,
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
                                labelText: 'username',
                                hintText: formatUsernameHint(
                                  store.state.userStore.homeserver,
                                ),
                                contentPadding: EdgeInsets.only(
                                  left: 20,
                                  top: 32,
                                ),
                                suffixIcon: IconButton(
                                  highlightColor:
                                      Theme.of(context).primaryColor,
                                  icon: Icon(Icons.help_outline),
                                  tooltip: SELECT_USERNAME_TITLE,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/search_home',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: defaultWidgetScaling,
                            height: Dimensions.inputHeight,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              minWidth: Dimensions.inputWidthMin,
                              maxWidth: Dimensions.inputWidthMax,
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
                    width: defaultWidgetScaling,
                    height: Dimensions.inputHeight,
                    margin: const EdgeInsets.only(
                      top: 24,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 256,
                      maxWidth: 336,
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
                              LOGIN_BUTTON_TEXT,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  Container(
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minHeight: Dimensions.inputHeight,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
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
                            CREATE_USER_TEXT,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              CREATE_USER_TEXT_ACTION,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w100,
                                color: Themes.invertedPrimaryColor(context),
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

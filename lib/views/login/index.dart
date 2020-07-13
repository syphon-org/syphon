import 'dart:async';

import 'package:syphon/global/strings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Store
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';

// Styling
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/behaviors.dart';

// Assets
import 'package:syphon/global/assets.dart';

class Login extends StatefulWidget {
  final Store<AppState> store;
  const Login({Key key, this.store}) : super(key: key);

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final passwordFocus = FocusNode();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final GlobalKey<ScaffoldState> loginScaffold = GlobalKey<ScaffoldState>();

  StreamSubscription alertsListener;
  bool visibility = false;

  LoginState({Key key});

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    // Init alerts listener
    alertsListener = store.state.alertsStore.onAlertsChanged.listen((alert) {
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
        content: Text(
          alert.message,
          style: Theme.of(context)
              .textTheme
              .subtitle1
              .copyWith(color: Colors.white),
        ),
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
    if (alertsListener != null) {
      alertsListener.cancel();
    }
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

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (store) => _Props.mapStateToProps(store),
      builder: (context, props) => Scaffold(
        key: loginScaffold,
        body: ScrollConfiguration(
          behavior: DefaultScrollBehavior(),
          child: SingleChildScrollView(
            // Use a container of the same height and width
            // to flex dynamically but within a single child scroll
            child: Container(
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
                            props.onIncrementTheme();
                          },
                          child: Image(
                            width: width * 0.35,
                            height: width * 0.35,
                            image: AssetImage(Assets.appIconPng),
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
                              Strings.titleLogin,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  .copyWith(
                                    color: Colors.white,
                                  ),
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
                              maxLines: 1,
                              autocorrect: false,
                              enableSuggestions: false,
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
                                props.onChangeUsername(username);
                              },
                              decoration: InputDecoration(
                                labelText: 'username',
                                hintText: props.usernameHint,
                                contentPadding: Dimensions.inputPadding,
                                suffixIcon: IconButton(
                                  highlightColor:
                                      Theme.of(context).primaryColor,
                                  icon: Icon(Icons.help_outline),
                                  tooltip: Strings.tooltipSelectHomeserver,
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
                                props.onChangePassword(password);
                              },
                              autocorrect: false,
                              enableSuggestions: false,
                              smartQuotesType: SmartQuotesType.disabled,
                              smartDashesType: SmartDashesType.disabled,
                              textAlign: TextAlign.left,
                              obscureText: !visibility,
                              decoration: InputDecoration(
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    if (!passwordFocus.hasFocus) {
                                      // Unfocus all focus nodes
                                      passwordFocus.unfocus();

                                      // Disable text field's focus node request
                                      passwordFocus.canRequestFocus = false;
                                    }

                                    // Do your stuff
                                    this.setState(() {
                                      visibility = !this.visibility;
                                    });

                                    if (!passwordFocus.hasFocus) {
                                      //Enable the text field's focus node request after some delay
                                      Future.delayed(
                                          Duration(milliseconds: 100), () {
                                        passwordFocus.canRequestFocus = true;
                                      });
                                    }
                                  },
                                  child: Icon(
                                    visibility
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                contentPadding: Dimensions.inputPadding,
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
                    child: ButtonSolid(
                      text: Strings.buttonLogin,
                      loading: props.loading,
                      disabled: !props.isLoginAttemptable,
                      onPressed: () => props.onLoginUser(),
                    ),
                  ),
                  Container(
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minHeight: Dimensions.inputHeight,
                    ),
                    margin: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 16,
                      bottom: 24,
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
                            Strings.buttonLoginCreateQuestion,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              Strings.buttonLoginCreateAction,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  .copyWith(
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

class _Props extends Equatable {
  final bool loading;
  final String username;
  final String password;
  final bool isLoginAttemptable;
  final String usernameHint;

  final Function onIncrementTheme;
  final Function onChangeUsername;
  final Function onChangePassword;
  final Function onLoginUser;

  _Props({
    @required this.loading,
    @required this.username,
    @required this.password,
    @required this.isLoginAttemptable,
    @required this.usernameHint,
    @required this.onIncrementTheme,
    @required this.onChangeUsername,
    @required this.onChangePassword,
    @required this.onLoginUser,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
      loading: store.state.authStore.loading,
      username: store.state.authStore.username,
      password: store.state.authStore.password,
      isLoginAttemptable: store.state.authStore.isPasswordValid &&
          store.state.authStore.isUsernameValid &&
          !store.state.authStore.loading,
      usernameHint: Strings.formatUsernameHint(
        store.state.authStore.homeserver,
      ),
      onChangeUsername: (String text) {
        // If user enters full username, make sure to set homeserver
        if (text.contains(':')) {
          final alias = text.trim().split(':');
          store.dispatch(setUsername(
            username: alias[0],
          ));
          store.dispatch(setHomeserver(
            homeserver: alias[1],
          ));
        } else {
          store.dispatch(setUsername(
            username: text.trim(),
          ));
          store.dispatch(setHomeserver(
            homeserver: 'matrix.org',
          ));
        }
      },
      onChangePassword: (String text) {
        store.dispatch(
          setPassword(password: text, ignoreConfirm: true),
        );
      },
      onIncrementTheme: () {
        store.dispatch(incrementTheme());
      },
      onLoginUser: () async {
        await store.dispatch(loginUser());
      });

  @override
  List<Object> get props => [
        loading,
        username,
        password,
        isLoginAttemptable,
        usernameHint,
      ];
}

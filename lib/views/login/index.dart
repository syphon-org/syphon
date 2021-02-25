// Dart imports:
import 'dart:async';
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

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
  bool visibility = false;

  LoginState({Key key});

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  buildSSOLogin(_Props props) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Avatar(
          size: Dimensions.avatarSizeMin,
          url: props.homeserver.photoUrl,
          alt: props.homeserver.hostname ?? '',
          background: Colours.hashedColor(props.homeserver.hostname),
        ),
        title: Text(
          props.homeserver.hostname ?? '',
          style: Theme.of(context).textTheme.headline6,
        ),
        subtitle: Text(
          props.homeserver.baseUrl ?? '',
          style: Theme.of(context).textTheme.caption,
        ),
        trailing: TouchableOpacity(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/search/homeservers',
            );
          },
          child: Icon(
            Icons.search_rounded,
            size: Dimensions.iconSizeLarge,
          ),
        ),
      ),
    );
  }

  buildPasswordLogin(_Props props) {
    return Column(
      children: [
        Container(
          height: Dimensions.inputHeight,
          margin: const EdgeInsets.only(
            bottom: 8,
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                props.onChangeHomeserver();
              }
            },
            child: TextFieldSecure(
              maxLines: 1,
              label: props.usernameHint,
              disableSpacing: true,
              controller: usernameController,
              autofillHints: [AutofillHints.username],
              formatters: [FilteringTextInputFormatter.deny(RegExp(r'@@'))],
              onSubmitted: (text) {
                FocusScope.of(context).requestFocus(passwordFocus);
              },
              onChanged: (username) {
                props.onChangeUsername(username);
              },
              suffix: TouchableOpacity(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/search/homeservers',
                  );
                },
                child: Icon(
                  Icons.search_rounded,
                ),
              ),
            ),
          ),
        ),
        Container(
          height: Dimensions.inputHeight,
          margin: const EdgeInsets.only(
            top: 8,
            bottom: 10,
          ),
          constraints: BoxConstraints(
            minWidth: Dimensions.inputWidthMin,
            maxWidth: Dimensions.inputWidthMax,
          ),
          child: TextFieldSecure(
            label: 'password',
            focusNode: passwordFocus,
            obscureText: !visibility,
            textAlign: TextAlign.left,
            autofillHints: [AutofillHints.password],
            onChanged: (password) {
              props.onChangePassword(password);
            },
            suffix: GestureDetector(
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
                  Future.delayed(Duration(milliseconds: 100), () {
                    passwordFocus.canRequestFocus = true;
                  });
                }
              },
              child: Icon(
                visibility ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
        ),
        Flex(
          direction: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(right: 4),
              child: TouchableOpacity(
                activeOpacity: 0.4,
                onTap: () async {
                  await props.onResetSession();
                  Navigator.pushNamed(
                    context,
                    '/forgot',
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Forgot Password?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (store) => _Props.mapStateToProps(store),
      builder: (context, props) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          brightness: Brightness.light,
          backgroundColor: Colors.transparent,
          actions: <Widget>[
            Visibility(
              maintainSize: false,
              visible: DotEnv().env['DEBUG'] == 'true',
              child: IconButton(
                icon: Icon(Icons.settings),
                iconSize: Dimensions.iconSizeLarge,
                tooltip: 'Debug (Future Tools)',
                color: Theme.of(context).scaffoldBackgroundColor,
                onPressed: () {
                  props.onDebug();
                },
              ),
            ),
          ],
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ),
        extendBodyBehindAppBar: true,
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
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 180,
                              maxHeight: 180,
                            ),
                            child: Image(
                              width: width * 0.35,
                              height: width * 0.35,
                              image: AssetImage(Assets.appIconPng),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    fit: FlexFit.loose,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: Dimensions.inputWidthMin,
                        maxWidth: Dimensions.inputWidthMax,
                      ),
                      child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Visibility(
                            visible:
                                props.loginType == MatrixAuthTypes.PASSWORD ||
                                    props.loginType == MatrixAuthTypes.DUMMY,
                            child: buildPasswordLogin(props),
                          ),
                          Visibility(
                            visible: props.loginType == MatrixAuthTypes.SSO,
                            child: buildSSOLogin(props),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 0,
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Container(
                            padding: const EdgeInsets.only(top: 26, bottom: 12),
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: props.loginType ==
                                          MatrixAuthTypes.PASSWORD ||
                                      props.loginType == MatrixAuthTypes.DUMMY,
                                  child: ButtonSolid(
                                    text: Strings.buttonLogin,
                                    loading: props.loading,
                                    disabled: !props.isLoginAttemptable,
                                    onPressed: () => props.onLoginUser(),
                                  ),
                                ),
                                Visibility(
                                  visible:
                                      props.loginType == MatrixAuthTypes.SSO,
                                  child: ButtonSolid(
                                    text: Strings.buttonLoginSSO,
                                    loading: props.loading,
                                    disabled: !props.isLoginAttemptable,
                                    onPressed: () => props.onLoginUser(),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: Dimensions.inputHeight,
                      constraints: BoxConstraints(
                        minHeight: Dimensions.inputHeight,
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
  final String loginType;
  final Homeserver homeserver;

  final Function onDebug;
  final Function onLoginUser;
  final Function onIncrementTheme;
  final Function onChangeUsername;
  final Function onChangePassword;
  final Function onChangeHomeserver;
  final Function onResetSession;

  _Props({
    @required this.loading,
    @required this.username,
    @required this.password,
    @required this.loginType,
    @required this.homeserver,
    @required this.isLoginAttemptable,
    @required this.usernameHint,
    @required this.onDebug,
    @required this.onLoginUser,
    @required this.onIncrementTheme,
    @required this.onChangeUsername,
    @required this.onChangePassword,
    @required this.onChangeHomeserver,
    @required this.onResetSession,
  });

  @override
  List<Object> get props => [
        loading,
        username,
        password,
        usernameHint,
        isLoginAttemptable,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        homeserver: store.state.authStore.homeserver,
        loginType: store.state.authStore.homeserver.loginType,
        isLoginAttemptable:
            store.state.authStore.homeserver.loginType == MatrixAuthTypes.SSO ||
                (store.state.authStore.isPasswordValid &&
                    store.state.authStore.isUsernameValid &&
                    !store.state.authStore.loading &&
                    !store.state.authStore.stopgap),
        usernameHint: Strings.formatUsernameHint(
          username: store.state.authStore.username,
          homeserver: store.state.authStore.hostname,
        ),
        onResetSession: () async {
          await store.dispatch(resetSession());
        },
        onChangeUsername: (String text) async {
          await store.dispatch(resolveUsername(username: text));
        },
        onChangeHomeserver: () async {
          final hostname = store.state.authStore.hostname;
          final homeserver = store.state.authStore.homeserver;

          if (hostname != homeserver.hostname) {
            await store.dispatch(selectHomeserver(hostname: hostname));
          }
        },
        onChangePassword: (String text) {
          store.dispatch(setLoginPassword(password: text));
        },
        onIncrementTheme: () {
          store.dispatch(incrementTheme());
        },
        onDebug: () async {
          store.dispatch(initClientSecret());
        },
        onLoginUser: () async {
          final hostname = store.state.authStore.hostname;
          final homeserver = store.state.authStore.homeserver;

          if (hostname != homeserver.hostname) {
            return store.dispatch(selectHomeserver(hostname: hostname));
          }

          if (homeserver.loginType == MatrixAuthTypes.SSO) {
            return await store.dispatch(loginUserSSO());
          }

          return await store.dispatch(loginUser());
        },
      );
}

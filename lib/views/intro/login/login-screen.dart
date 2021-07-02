import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/auth/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:syphon/global/assets.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

class LoginScreen extends StatefulWidget {
  final Store<AppState>? store;
  const LoginScreen({Key? key, this.store}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final passwordFocus = FocusNode();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool visibility = false;
  AuthTypes? currentAuthType;

  LoginScreenState();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  onLoginPassword(_Props props) async {
    setState(() {
      currentAuthType = AuthTypes.Password;
    });

    await props.onLoginUser();

    setState(() {
      currentAuthType = null;
    });
  }

  onLoginSSO(_Props props) async {
    setState(() {
      currentAuthType = AuthTypes.SSO;
    });

    await props.onLoginUserSSO();

    setState(() {
      currentAuthType = null;
    });
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
              autofillHints: const [AutofillHints.username],
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
            autofillHints: const [AutofillHints.password],
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
                setState(() {
                  visibility = !visibility;
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
                  children: const <Widget>[
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
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

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
              visible: DEBUG_MODE,
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
                            visible: props.isPasswordEnabled,
                            child: buildPasswordLogin(props),
                          ),
                          Visibility(
                            visible: props.isSSOEnabled && !props.isPasswordEnabled,
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
                            child: Column(
                              children: [
                                Visibility(
                                  visible: props.isPasswordEnabled,
                                  child: ButtonSolid(
                                    text: Strings.buttonLogin,
                                    loading: props.loading && currentAuthType == AuthTypes.Password,
                                    disabled: !props.isPasswordLoginAttemptable || currentAuthType != null,
                                    onPressed: () => onLoginPassword(props),
                                  ),
                                ),
                                Visibility(
                                  visible: props.isSSOEnabled,
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                                    child: ButtonSolid(
                                      text: Strings.buttonLoginSSO,
                                      loading: props.loading && currentAuthType == AuthTypes.SSO,
                                      disabled: !props.isSSOLoginAttemptable || currentAuthType != null,
                                      onPressed: () => onLoginSSO(props),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  Flexible(
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
                                style: Theme.of(context).textTheme.bodyText2!.copyWith(
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
  final bool isPasswordLoginAttemptable;
  final bool isSSOLoginAttemptable;
  final String usernameHint;
  final List<String> loginTypes;
  final Homeserver homeserver;

  final bool isPasswordEnabled;
  final bool isSSOEnabled;

  final Function onDebug;
  final Function onLoginUser;
  final Function onLoginUserSSO;
  final Function onIncrementTheme;
  final Function onChangeUsername;
  final Function onChangePassword;
  final Function onChangeHomeserver;
  final Function onResetSession;

  const _Props({
    required this.loading,
    required this.username,
    required this.password,
    required this.loginTypes,
    required this.isPasswordEnabled,
    required this.isSSOEnabled,
    required this.homeserver,
    required this.isPasswordLoginAttemptable,
    required this.isSSOLoginAttemptable,
    required this.usernameHint,
    required this.onDebug,
    required this.onLoginUser,
    required this.onLoginUserSSO,
    required this.onIncrementTheme,
    required this.onChangeUsername,
    required this.onChangePassword,
    required this.onChangeHomeserver,
    required this.onResetSession,
  });

  @override
  List<Object> get props => [
        loading,
        username,
        password,
        usernameHint,
        isPasswordLoginAttemptable,
        isSSOLoginAttemptable,
        loginTypes,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        homeserver: store.state.authStore.homeserver,
        loginTypes: store.state.authStore.homeserver.loginTypes,
        isSSOEnabled: selectSSOEnabled(store.state),
        isPasswordEnabled: selectPasswordEnabled(store.state),
        isPasswordLoginAttemptable: selectPasswordLoginAttemptable(store.state),
        isSSOLoginAttemptable: selectSSOLoginAttemptable(store.state),
        usernameHint: Strings.formatUsernameHint(
          username: store.state.authStore.username,
          homeserver: store.state.authStore.hostname,
        ),
        onResetSession: () async {
          await store.dispatch(resetInteractiveAuth());
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
        onLoginUserSSO: () async {
          final hostname = store.state.authStore.hostname;
          final homeserver = store.state.authStore.homeserver;

          if (hostname != homeserver.hostname) {
            return store.dispatch(selectHomeserver(hostname: hostname));
          }

          return await store.dispatch(loginUserSSO());
        },
        onLoginUser: () async {
          final hostname = store.state.authStore.hostname;
          final homeserver = store.state.authStore.homeserver;

          if (hostname != homeserver.hostname) {
            return store.dispatch(selectHomeserver(hostname: hostname));
          }
          return await store.dispatch(loginUser());
        },
      );
}

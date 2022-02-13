import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/auth/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class LoginScreenArguments {
  final bool multiaccount;
  LoginScreenArguments({this.multiaccount = true});
}

class LoginScreen extends StatefulWidget {
  final Store<AppState>? store;
  const LoginScreen({Key? key, this.store}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> with Lifecycle<LoginScreen> {
  final passwordFocus = FocusNode();
  final usernameController = TextEditingController();
  final avatarHash = Random().nextInt(2);

  bool visibility = false;
  AuthTypes? currentAuthType;

  LoginScreenState();

  @override
  void dispose() {
    super.dispose();
  }

  onLoginPassword(_Props props) async {
    setState(() {
      currentAuthType = AuthTypes.Password;
    });

    final userId = props.userIdHint;

    final authExists = props.availableUsers.indexWhere(
      (user) => user.userId == userId,
    );

    if (authExists != -1) {
      props.onAddAlert(
        'User already logged in under multiaccounts',
      );
    } else {
      await props.onLoginUser();
    }

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

  onToggleShowPassword() {
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
  }

  buildSSOLogin(_Props props) => Container(
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
            Navigator.pushNamed(context, Routes.searchHomeservers);
          },
          child: Icon(
            Icons.search_rounded,
            size: Dimensions.iconSizeLarge,
          ),
        ),
      ));

  buildPasswordLogin(_Props props) => Column(children: [
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
              label: props.userIdHint,
              disableSpacing: true,
              disabled: props.loading,
              controller: usernameController,
              autofillHints: const [AutofillHints.username],
              formatters: [FilteringTextInputFormatter.deny(RegExp('@@'))],
              onSubmitted: (text) {
                FocusScope.of(context).requestFocus(passwordFocus);
              },
              onChanged: (username) {
                props.onChangeUsername(username);
              },
              suffix: TouchableOpacity(
                onTap: () {
                  Navigator.pushNamed(context, Routes.searchHomeservers);
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
            disabled: props.loading,
            focusNode: passwordFocus,
            obscureText: !visibility,
            textAlign: TextAlign.left,
            autofillHints: const [AutofillHints.password],
            onChanged: (password) {
              props.onChangePassword(password);
            },
            suffix: GestureDetector(
              onTap: () => onToggleShowPassword(),
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
                  Navigator.pushNamed(context, Routes.forgot);
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
      ]);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    final args = ModalRoute.of(context)!.settings.arguments as LoginScreenArguments?;

    final multiaccount = args?.multiaccount ?? false;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      onInitialBuild: (props) {
        if (multiaccount) {
          final store = StoreProvider.of<AppState>(context);
          store.dispatch(initDeepLinks());
        }
      },
      converter: (store) => _Props.mapStateToProps(store),
      builder: (context, props) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          systemOverlayStyle: computeSystemUIColor(context),
          backgroundColor: Colors.transparent,
          actions: <Widget>[
            Visibility(
              visible: DEBUG_MODE,
              child: IconButton(
                icon: Icon(Icons.settings),
                iconSize: Dimensions.iconSizeLarge,
                tooltip: 'General Settings',
                color: Theme.of(context).scaffoldBackgroundColor,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.settingsTheme);
                  props.onDebug();
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert),
              iconSize: Dimensions.iconSizeLarge,
              tooltip: Strings.listItemSettingsProxy,
              color: Theme.of(context).primaryColor,
              onPressed: () {
                Navigator.pushNamed(context, Routes.settingsProxy);
              },
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
        body: ScrollConfiguration(
          behavior: DefaultScrollBehavior(),
          child: SingleChildScrollView(
            // Use a container of the same height and width
            // to flex dynamically but within a single child scroll
            child: Container(
              height: height,
              width: width,
              constraints: BoxConstraints(
                maxHeight: Dimensions.heightMax,
              ),
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    flex: 4,
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Visibility(
                          visible: !multiaccount,
                          child: TouchableOpacity(
                            onTap: () {
                              props.onIncrementThemeType();
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
                        ),
                        Visibility(
                          visible: multiaccount,
                          child: Flexible(
                            flex: 0,
                            child: Flex(
                              direction: Axis.vertical,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                TouchableOpacity(
                                  onTap: () {
                                    props.onIncrementThemeType();
                                  },
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: 180,
                                      maxHeight: 180,
                                    ),
                                    child: SvgPicture.asset(
                                      avatarHash % 2 == 0
                                          ? Assets.heroAvatarFemale
                                          : Assets.heroAvatarMale,
                                      width: width * 0.35,
                                      height: width * 0.35,
                                    ),
                                  ),
                                )
                              ],
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
                            visible: multiaccount,
                            child: Flexible(
                              flex: 1,
                              child: Flex(
                                direction: Axis.vertical,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.only(bottom: Dimensions.paddingSmall),
                                    child: Text(
                                      'Add another account',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline5,
                                    ),
                                  ),
                                  Text(
                                    'Login to switch between\ndifferent accounts you own',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyText2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: props.isPasswordLoginAvailable,
                            child: buildPasswordLogin(props),
                          ),
                          Visibility(
                            visible: props.isSSOLoginAvailable && !props.isPasswordLoginAvailable,
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
                                  visible: props.isPasswordLoginAvailable,
                                  child: ButtonSolid(
                                    text: Strings.buttonLogin,
                                    loading: props.loading && currentAuthType == AuthTypes.Password,
                                    disabled: !props.isPasswordLoginAttemptable ||
                                        currentAuthType != null,
                                    onPressed: () => onLoginPassword(props),
                                  ),
                                ),
                                Visibility(
                                  visible:
                                      props.isSSOLoginAvailable && !props.isPasswordLoginAvailable,
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                                    child: ButtonSolid(
                                      text: Strings.buttonLoginSSO,
                                      loading: props.loading && currentAuthType == AuthTypes.SSO,
                                      disabled:
                                          !props.isSSOLoginAttemptable || currentAuthType != null,
                                      onPressed: () => onLoginSSO(props),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible:
                                      props.isSSOLoginAvailable && props.isPasswordLoginAvailable,
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                                    child: ButtonText(
                                      text: Strings.buttonLoginSSO,
                                      loading: props.loading && currentAuthType == AuthTypes.SSO,
                                      disabled:
                                          !props.isSSOLoginAttemptable || currentAuthType != null,
                                      onPressed: () => onLoginSSO(props),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: !multiaccount,
                    child: Flexible(
                      child: Container(
                        height: Dimensions.inputHeight,
                        constraints: BoxConstraints(
                          minHeight: Dimensions.inputHeight,
                        ),
                        child: TouchableOpacity(
                          activeOpacity: 0.4,
                          onTap: () => Navigator.pushNamed(context, Routes.signup),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                Strings.buttonTextSignupQuestion,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  Strings.buttonTextSignupAction,
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
  final String userIdHint;
  final String username;
  final String password;

  final bool loading;
  final bool isPasswordLoginAvailable;
  final bool isPasswordLoginAttemptable;
  final bool isSSOLoginAvailable;
  final bool isSSOLoginAttemptable;

  final Homeserver homeserver;

  final List<User> availableUsers;

  final Function onDebug;
  final Function onLoginUser;
  final Function onLoginUserSSO;
  final Function onIncrementThemeType;
  final Function onChangeUsername;
  final Function onChangePassword;
  final Function onChangeHomeserver;
  final Function onAddAlert;
  final Function onResetSession;

  const _Props({
    required this.loading,
    required this.userIdHint,
    required this.username,
    required this.password,
    required this.availableUsers,
    required this.isPasswordLoginAvailable,
    required this.isSSOLoginAvailable,
    required this.homeserver,
    required this.isPasswordLoginAttemptable,
    required this.isSSOLoginAttemptable,
    required this.onDebug,
    required this.onAddAlert,
    required this.onLoginUser,
    required this.onLoginUserSSO,
    required this.onIncrementThemeType,
    required this.onChangeUsername,
    required this.onChangePassword,
    required this.onChangeHomeserver,
    required this.onResetSession,
  });

  @override
  List<Object> get props => [
        loading,
        userIdHint,
        username,
        password,
        availableUsers,
        onIncrementThemeType,
        isPasswordLoginAttemptable,
        isSSOLoginAttemptable,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        homeserver: store.state.authStore.homeserver,
        availableUsers: store.state.authStore.availableUsers,
        isSSOLoginAvailable: selectSSOEnabled(store.state),
        isPasswordLoginAvailable: selectPasswordEnabled(store.state),
        isSSOLoginAttemptable: selectSSOLoginAttemptable(store.state),
        isPasswordLoginAttemptable: selectPasswordLoginAttemptable(store.state),
        userIdHint: formatUsernameHint(
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
        onIncrementThemeType: () {
          store.dispatch(incrementThemeType());
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
        onAddAlert: (message) {
          store.dispatch(addAlert(
            origin: 'LoginScreen',
            message: message,
          ));
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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syphon/domain/alerts/actions.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/domain/auth/homeserver/model.dart';
import 'package:syphon/domain/auth/selectors.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/theme-settings/actions.dart';
import 'package:syphon/domain/settings/theme-settings/selectors.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/hooks.dart';
import 'package:syphon/global/libraries/matrix/auth/types.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class LoginScreenArguments {
  final bool multiaccount;
  LoginScreenArguments({this.multiaccount = true});
}

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();
    final Size(:width, :height) = useDimensions(context);
    final LoginScreenArguments(:multiaccount) = useArguments<LoginScreenArguments>(context);

    final passwordFocus = useFocusNode();
    final usernameController = useTextEditingController();
    final avatarHash = useMemoized(() => Random().nextInt(2), []);

    final (visibility, setVisibility) = useStateful<bool>(false);
    final (currentAuthType, setCurrentAuthType) = useStateful<AuthTypes?>(AuthTypes.Password);

    final loading = useSelector<AppState, bool>((state) => state.authStore.loading, false);
    final hostname = useSelector<AppState, String>((state) => state.authStore.hostname, Values.empty);
    final username = useSelector<AppState, String>((state) => state.authStore.username, Values.empty);
    final homeserver = useSelector<AppState, Homeserver>((state) => state.authStore.homeserver, Homeserver());

    final availableUsers = useSelector<AppState, List<User>>(
      (state) => state.authStore.availableUsers,
      const [],
    );

    final userIdHint = useMemoized<String>(
      () => formatUsernameHint(username: username, homeserver: hostname),
      [username, hostname],
    );

    useEffect(() {
      if (multiaccount) {
        dispatch(initDeepLinks());
      }
    }, []);

    final isSSOLoginAvailable = useSelector<AppState, bool>((state) => selectSSOEnabled(state), false);

    final isPasswordLoginAvailable =
        useSelector<AppState, bool>((state) => selectPasswordEnabled(state), false);

    final isSSOLoginAttemptable =
        useSelector<AppState, bool>((state) => selectSSOLoginAttemptable(state), false);

    final isPasswordLoginAttemptable =
        useSelector<AppState, bool>((state) => selectPasswordLoginAttemptable(state), false);

    onResetSession() async {
      await dispatch(resetInteractiveAuth());
    }

    onChangeUsername(String text) async {
      await dispatch(resolveUsername(username: text));
    }

    onChangeHomeserver() async {
      if (hostname != homeserver.hostname) {
        await dispatch(selectHomeserver(hostname: hostname));
      }
    }

    onChangePassword(String text) {
      dispatch(setLoginPassword(password: text));
    }

    onIncrementThemeType() {
      dispatch(incrementThemeType());
    }

    onDebug() async {
      dispatch(initClientSecret());
    }

    onLoginUserSSO() async {
      if (hostname != homeserver.hostname) {
        return dispatch(selectHomeserver(hostname: hostname));
      }

      return await dispatch(loginUserSSO());
    }

    onAddAlert(message) {
      dispatch(addAlert(
        origin: 'LoginScreen',
        message: message,
      ));
    }

    onLoginUser() async {
      if (hostname != homeserver.hostname) {
        return dispatch(selectHomeserver(hostname: hostname));
      }
      return await dispatch(loginUser());
    }

    onLoginPassword() async {
      setCurrentAuthType(AuthTypes.Password);

      final authExists = availableUsers.indexWhere(
        (user) => user.userId == userIdHint,
      );

      if (authExists != -1) {
        onAddAlert(
          'User already logged in under multiaccounts',
        );
      } else {
        await onLoginUser();
      }

      setCurrentAuthType(null);
    }

    onLoginSSO() async {
      setCurrentAuthType(AuthTypes.SSO);

      await onLoginUserSSO();

      setCurrentAuthType(null);
    }

    onToggleShowPassword() {
      if (!passwordFocus.hasFocus) {
        // Unfocus all focus nodes
        passwordFocus.unfocus();

        // Disable text field's focus node request
        passwordFocus.canRequestFocus = false;
      }

      // Do your stuff
      setVisibility(!visibility);

      if (!passwordFocus.hasFocus) {
        //Enable the text field's focus node request after some delay
        Future.delayed(Duration(milliseconds: 100), () {
          passwordFocus.canRequestFocus = true;
        });
      }
    }

    buildSSOLogin() => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Avatar(
            size: Dimensions.avatarSizeMin,
            url: homeserver.photoUrl,
            alt: homeserver.hostname ?? '',
            background: AppColors.hashedColor(homeserver.hostname),
          ),
          title: Text(
            homeserver.hostname ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            homeserver.baseUrl ?? '',
            style: Theme.of(context).textTheme.bodySmall,
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

    buildPasswordLogin() => Column(children: [
          Container(
            height: Dimensions.inputHeight,
            margin: const EdgeInsets.only(
              bottom: 8,
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  onChangeHomeserver();
                }
              },
              child: TextFieldSecure(
                maxLines: 1,
                label: userIdHint,
                disableSpacing: true,
                disabled: loading,
                controller: usernameController,
                autofillHints: const [AutofillHints.username],
                formatters: [FilteringTextInputFormatter.deny(RegExp('@@'))],
                onSubmitted: (text) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
                onChanged: (username) {
                  onChangeUsername(username);
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
              disabled: loading,
              focusNode: passwordFocus,
              obscureText: !visibility,
              textAlign: TextAlign.left,
              autofillHints: const [AutofillHints.password],
              onChanged: (password) {
                onChangePassword(password);
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
                    await onResetSession();
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

    return Scaffold(
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
                onDebug();
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
                            onIncrementThemeType();
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
                                  onIncrementThemeType();
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: 180,
                                    maxHeight: 180,
                                  ),
                                  child: SvgPicture.asset(
                                    avatarHash.isEven ? Assets.heroAvatarFemale : Assets.heroAvatarMale,
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
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ),
                                Text(
                                  'Login to switch between\ndifferent accounts you own',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: isPasswordLoginAvailable,
                          child: buildPasswordLogin(),
                        ),
                        Visibility(
                          visible: isSSOLoginAvailable && !isPasswordLoginAvailable,
                          child: buildSSOLogin(),
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
                                visible: isPasswordLoginAvailable,
                                child: ButtonSolid(
                                  text: Strings.buttonLogin,
                                  loading: loading && currentAuthType == AuthTypes.Password,
                                  disabled: !isPasswordLoginAttemptable || currentAuthType != null,
                                  onPressed: () => onLoginPassword(),
                                ),
                              ),
                              Visibility(
                                visible: isSSOLoginAvailable && !isPasswordLoginAvailable,
                                child: Container(
                                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                                  child: ButtonSolid(
                                    text: Strings.buttonLoginSSO,
                                    loading: loading && currentAuthType == AuthTypes.SSO,
                                    disabled: !isSSOLoginAttemptable || currentAuthType != null,
                                    onPressed: () => onLoginSSO(),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: isSSOLoginAvailable && isPasswordLoginAvailable,
                                child: Container(
                                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                                  child: ButtonText(
                                    text: Strings.buttonLoginSSO,
                                    loading: loading && currentAuthType == AuthTypes.SSO,
                                    disabled: !isSSOLoginAttemptable || currentAuthType != null,
                                    onPressed: () => onLoginSSO(),
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
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
    );
  }
}

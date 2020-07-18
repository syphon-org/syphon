import 'dart:async';

import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'state.g.dart';

@HiveType(typeId: AuthStoreHiveId)
class AuthStore extends Equatable {
  @HiveField(0)
  final User user;
  User get currentUser => user;

  final StreamController<User> authObserver;
  Stream<User> get onAuthStateChanged =>
      authObserver != null ? authObserver.stream : null;

  // Interactive Auth Data
  final String session;
  final Credential credential;
  final List<String> completed;
  final Map<String, dynamic> interactiveAuths;

  // Temporary Signup Params
  final String email;
  final String username;
  final String password;
  final String passwordCurrent;
  final String passwordConfirm;
  final String homeserver;
  final String loginType;
  final bool agreement;
  final bool captcha;

  // Temporary state propertie
  final bool loading;
  final bool creating;
  final bool isEmailValid;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;
  final bool isUsernameAvailable;

  const AuthStore({
    this.user = const User(),
    this.authObserver,
    this.email = '',
    this.username = '', // null
    this.password = '', // null
    this.passwordCurrent = '', // null
    this.passwordConfirm = '',
    this.agreement = false,
    this.captcha = false,
    this.session,
    this.completed = const [],
    this.homeserver = Values.homeserverDefault,
    this.loginType = 'm.login.dummy',
    this.interactiveAuths = const {},
    this.isEmailValid = false,
    this.isUsernameValid = false,
    this.isUsernameAvailable = false,
    this.isPasswordValid = false,
    this.isHomeserverValid = true,
    this.credential,
    this.creating = false,
    this.loading = false,
  });

  AuthStore copyWith({
    user,
    email,
    loading,
    username,
    password,
    passwordConfirm,
    passwordCurrent,
    agreement,
    homeserver,
    completed,
    captcha,
    session,
    isHomeserverValid,
    isUsernameValid,
    isUsernameAvailable,
    isPasswordValid,
    isEmailValid,
    interactiveAuths,
    interactiveStages,
    credential,
    creating,
    authObserver,
  }) {
    return AuthStore(
      user: user ?? this.user,
      email: email ?? this.email,
      loading: loading ?? this.loading,
      authObserver: authObserver ?? this.authObserver,
      username: username ?? this.username,
      password: password ?? this.password,
      agreement: agreement ?? this.agreement,
      passwordCurrent: passwordCurrent ?? this.passwordCurrent,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      homeserver: homeserver ?? this.homeserver,
      completed: completed ?? this.completed,
      captcha: captcha ?? this.captcha,
      session: session ?? this.session,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isUsernameValid: isUsernameValid ?? this.isUsernameValid,
      isUsernameAvailable: isUsernameAvailable != null
          ? isUsernameAvailable
          : this.isUsernameAvailable,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isHomeserverValid: isHomeserverValid ?? this.isHomeserverValid,
      interactiveAuths: interactiveAuths ?? this.interactiveAuths,
      credential: credential ?? this.credential,
      creating: creating ?? this.creating,
    );
  }

  @override
  List<Object> get props => [
        user,
        authObserver,
        username,
        password,
        passwordConfirm,
        passwordCurrent,
        agreement,
        captcha,
        homeserver,
        completed,
        session,
        loginType,
        isEmailValid,
        isUsernameValid,
        isPasswordValid,
        isHomeserverValid,
        isUsernameAvailable,
        interactiveAuths,
        credential,
        loading,
        creating,
      ];
}

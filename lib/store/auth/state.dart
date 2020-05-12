import 'dart:async';

import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:Tether/store/auth/credential/model.dart';
import 'package:Tether/store/user/model.dart';
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

  // TODO: this is lazy
  // Interactive Auth Data
  final String session;
  final Credential credential;
  final Map<String, dynamic> interactiveAuths;

  // Temporary Signup Params
  final String username;
  final String password;
  final String passwordConfirm;
  final String homeserver;
  final String loginType;
  final bool agreement;
  final bool captcha;

  // Temporary state propertie
  final bool loading;
  final bool creating;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;
  final bool isUsernameAvailable;

  const AuthStore({
    this.user = const User(),
    this.authObserver,
    this.username = '', // null
    this.password = '', // null
    this.passwordConfirm = '',
    this.agreement = false,
    this.captcha = false,
    this.session,
    this.homeserver = 'matrix.org',
    this.loginType = 'm.login.dummy',
    this.interactiveAuths = const {},
    this.isUsernameValid = false,
    this.isUsernameAvailable = false,
    this.isPasswordValid = false,
    this.isHomeserverValid = false,
    this.credential,
    this.creating = false,
    this.loading = false,
  });

  AuthStore copyWith({
    user,
    loading,
    username,
    password,
    passwordConfirm,
    agreement,
    homeserver,
    captcha,
    session,
    isUsernameValid,
    isUsernameAvailable,
    isPasswordValid,
    isHomeserverValid,
    interactiveAuths,
    interactiveStages,
    credential,
    creating,
    authObserver,
  }) {
    return AuthStore(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      authObserver: authObserver ?? this.authObserver,
      username: username ?? this.username,
      password: password ?? this.password,
      agreement: agreement ?? this.agreement,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      homeserver: homeserver ?? this.homeserver,
      captcha: captcha ?? this.captcha,
      session: session ?? this.session,
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
        agreement,
        captcha,
        homeserver,
        session,
        loginType,
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

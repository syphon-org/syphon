// Dart imports:
import 'dart:async';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/libs/matrix/auth.dart';

// Project imports:
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/user/model.dart';

part 'state.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class AuthStore extends Equatable {
  @JsonKey()
  final User user;

  @JsonKey()
  final String? session; // a.k.a sid or session id

  @JsonKey()
  final String? clientSecret;

  @JsonKey()
  final String? protocol;

  User get currentUser => user;

  final StreamController<User?>? authObserver;

  Stream<User?>? get onAuthStateChanged =>
      authObserver != null ? authObserver!.stream : null;

  // Interactive Auth Data
  final Credential? credential;
  final List<String> completed;
  final Map<String, dynamic> interactiveAuths;

  // temp state values for signup
  final String email;
  final String username;
  final String password;
  final String passwordCurrent;
  final String passwordConfirm;
  final String hostname; // used pre sign up
  final Homeserver homeserver; // used during signup and login
  final bool agreement;
  final bool captcha;

  // temp state statuses for signup
  final bool loading;
  final bool stopgap;
  final bool creating;
  final bool verificationNeeded;
  final bool isEmailValid;
  final bool isEmailAvailable;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;
  final bool isUsernameAvailable;

  const AuthStore({
    this.user = const User(),
    this.session,
    this.clientSecret,
    this.authObserver,
    this.protocol = 'https://',
    this.email = '',
    this.username = '', // null
    this.password = '', // null
    this.passwordCurrent = '', // null
    this.passwordConfirm = '',
    this.agreement = false,
    this.captcha = false,
    this.completed = const [],
    this.hostname = Values.homeserverDefault,
    this.homeserver = const Homeserver(
      valid: true,
      hostname: "matrix.org",
      baseUrl: "matrix.org",
      loginType: MatrixAuthTypes.DUMMY,
    ),
    this.interactiveAuths = const {},
    this.isEmailValid = false,
    this.isEmailAvailable = true,
    this.isUsernameValid = false,
    this.isUsernameAvailable = false,
    this.isPasswordValid = false,
    this.isHomeserverValid = true,
    this.credential,
    this.stopgap = false,
    this.creating = false,
    this.loading = false,
    this.verificationNeeded = false,
  });

  @override
  List<Object?> get props => [
        user,
        session,
        clientSecret,
        authObserver,
        username,
        password,
        passwordConfirm,
        passwordCurrent,
        agreement,
        captcha,
        hostname,
        homeserver,
        completed,
        isEmailValid,
        isEmailAvailable,
        isUsernameValid,
        isPasswordValid,
        isHomeserverValid,
        isUsernameAvailable,
        interactiveAuths,
        credential,
        loading,
        creating,
        verificationNeeded,
      ];

  AuthStore copyWith({
    user,
    session,
    clientSecret,
    protocol,
    email,
    loading,
    username,
    password,
    passwordConfirm,
    passwordCurrent,
    agreement,
    hostname,
    homeserver,
    completed,
    captcha,
    isHomeserverValid,
    isUsernameValid,
    isUsernameAvailable,
    isPasswordValid,
    isEmailValid,
    isEmailAvailable,
    interactiveAuths,
    interactiveStages,
    credential,
    creating,
    verificationNeeded,
    authObserver,
  }) =>
      AuthStore(
        user: user ?? this.user,
        session: session ?? this.session,
        clientSecret: clientSecret ?? this.clientSecret,
        protocol: protocol ?? this.protocol,
        email: email ?? this.email,
        loading: loading ?? this.loading,
        authObserver: authObserver ?? this.authObserver,
        username: username ?? this.username,
        password: password ?? this.password,
        agreement: agreement ?? this.agreement,
        passwordCurrent: passwordCurrent ?? this.passwordCurrent,
        passwordConfirm: passwordConfirm ?? this.passwordConfirm,
        hostname: hostname ?? this.hostname,
        homeserver: homeserver ?? this.homeserver,
        completed: completed ?? this.completed,
        captcha: captcha ?? this.captcha,
        isEmailValid: isEmailValid ?? this.isEmailValid,
        isEmailAvailable: isEmailAvailable ?? this.isEmailAvailable,
        isUsernameValid: isUsernameValid ?? this.isUsernameValid,
        isUsernameAvailable: isUsernameAvailable != null
            ? isUsernameAvailable
            : this.isUsernameAvailable,
        isPasswordValid: isPasswordValid ?? this.isPasswordValid,
        isHomeserverValid: isHomeserverValid ?? this.isHomeserverValid,
        interactiveAuths: interactiveAuths ?? this.interactiveAuths,
        credential: credential ?? this.credential,
        creating: creating ?? this.creating,
        stopgap: stopgap,
        verificationNeeded: verificationNeeded ?? this.verificationNeeded,
      );

  Map<String, dynamic> toJson() => _$AuthStoreToJson(this);

  factory AuthStore.fromJson(Map<String, dynamic> json) =>
      _$AuthStoreFromJson(json);
}

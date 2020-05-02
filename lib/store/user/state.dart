import 'dart:async';

import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:Tether/store/user/model.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'state.g.dart';

@HiveType(typeId: UserStoreHiveId)
class UserStore extends Equatable {
  @HiveField(0)
  final User user;

  // TODO: consider making a user map

  // TODO: move to auth store
  final String username;
  final String password;
  final String homeserver;
  final String loginType;
  final bool isUsernameValid;
  final bool isPasswordValid;
  final bool isHomeserverValid;
  final bool isUsernameAvailable;

  // temporary state propertie
  final bool loading;
  final bool creating;
  final String newAvatarUri;
  final StreamController<User> authObserver;

  Stream<User> get onAuthStateChanged =>
      authObserver != null ? authObserver.stream : null;

  const UserStore({
    this.user = const User(),
    this.authObserver,
    this.username = '', // null
    this.password = '', // null
    this.homeserver = 'matrix.org',
    this.loginType = 'm.login.dummy',
    this.isUsernameValid = false,
    this.isUsernameAvailable = false,
    this.isPasswordValid = false,
    this.isHomeserverValid = false,
    this.newAvatarUri,
    this.creating = false,
    this.loading = false,
  });

  UserStore copyWith({
    user,
    loading,
    username,
    password,
    homeserver,
    isUsernameValid,
    isUsernameAvailable,
    isPasswordValid,
    isHomeserverValid,
    creating,
    authObserver,
  }) {
    return UserStore(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      authObserver: authObserver ?? this.authObserver,
      username: username ?? this.username,
      password: password ?? this.password,
      homeserver: homeserver ?? this.homeserver,
      isUsernameValid: isUsernameValid ?? this.isUsernameValid,
      isUsernameAvailable: isUsernameAvailable != null
          ? isUsernameAvailable
          : this.isUsernameAvailable,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isHomeserverValid: isHomeserverValid ?? this.isHomeserverValid,
      newAvatarUri: newAvatarUri ?? this.newAvatarUri,
      creating: creating ?? this.creating,
    );
  }

  @override
  List<Object> get props => [
        user,
        authObserver,
        username,
        password,
        homeserver,
        loginType,
        isUsernameValid,
        isPasswordValid,
        isHomeserverValid,
        isUsernameAvailable,
        loading,
        creating,
      ];
}

import 'package:syphon/domain/auth/context/actions.dart';

import './actions.dart';
import './state.dart';
import '../user/model.dart';

AuthStore authReducer([AuthStore state = const AuthStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: actionAny.loading);
    case SetCreating:
      return state.copyWith(creating: actionAny.creating);
    case SetAuthObserver:
      return state.copyWith(authObserver: actionAny.authObserver);
    case SetContextObserver:
      return state.copyWith(contextObserver: actionAny.contextObserver);
    case SetUser:
      final action = actionAny as SetUser;
      final availableUsers = List<User>.from(state.availableUsers);
      final hasUser = availableUsers.indexWhere(
        (user) => user.userId == action.user.userId,
      );

      if (hasUser != -1) {
        availableUsers.replaceRange(hasUser, hasUser + 1, [
          action.user.copyWith(accessToken: ''),
        ]);
      }

      return state.copyWith(
        user: action.user,
        availableUsers: availableUsers,
      );
    case SetSession:
      final action = actionAny as SetSession;
      return state.copyWith(authSession: action.session);
    case SetClientSecret:
      final action = actionAny as SetClientSecret;
      return state.copyWith(clientSecret: action.clientSecret);
    case SetCompleted:
      final action = actionAny as SetCompleted;
      return state.copyWith(completed: action.completed);
    case SetCredential:
      return state.copyWith(credential: actionAny.credential);
    case SetInteractiveAuths:
      return state.copyWith(interactiveAuths: actionAny.interactiveAuths);
    case SetHostname:
      return state.copyWith(hostname: actionAny.hostname);
    case SetHomeserver:
      return state.copyWith(homeserver: actionAny.homeserver);
    case SetUsername:
      return state.copyWith(username: actionAny.username);
    case SetUsernameValid:
      return state.copyWith(isUsernameValid: actionAny.valid);
    case SetUsernameAvailability:
      return state.copyWith(isUsernameAvailable: actionAny.availability);
    case SetPassword:
      return state.copyWith(password: actionAny.password);
    case SetPasswordConfirm:
      return state.copyWith(passwordConfirm: actionAny.password);
    case SetPasswordCurrent:
      return state.copyWith(passwordCurrent: actionAny.password);
    case SetPasswordValid:
      return state.copyWith(isPasswordValid: actionAny.valid);
    case SetEmail:
      return state.copyWith(email: actionAny.email);
    case SetEmailValid:
      return state.copyWith(isEmailValid: actionAny.valid);
    case SetEmailAvailability:
      return state.copyWith(isEmailAvailable: actionAny.available);
    case SetVerificationNeeded:
      return state.copyWith(verificationNeeded: actionAny.needed);
    case SetCaptcha:
      return state.copyWith(captcha: actionAny.completed);
    case SetAgreement:
      return state.copyWith(agreement: actionAny.agreement);
    case AddAvailableUser:
      final action = actionAny as AddAvailableUser;
      final availableUser = action.availableUser;
      final availableUsers = List<User>.from(state.availableUsers);

      final existingIndex = availableUsers.indexWhere((user) => user.userId == availableUser.userId);

      if (existingIndex == -1) {
        availableUsers.add(availableUser);
      }

      return state.copyWith(availableUsers: availableUsers);
    case RemoveAvailableUser:
      final action = actionAny as RemoveAvailableUser;
      final availableUser = action.availableUser;
      final availableUsers = List<User>.from(state.availableUsers);

      final existingIndex = availableUsers.indexWhere((user) => user.userId == availableUser.userId);

      if (existingIndex != -1) {
        availableUsers.remove(availableUser);
      }

      return state.copyWith(availableUsers: availableUsers);
    case ResetUser:
      return state.copyWith(user: const User());
    case ResetOnboarding:
      return state.copyWith(
        username: '',
        password: '',
        passwordConfirm: '',
        passwordCurrent: '',
        isPasswordValid: false,
        isUsernameValid: false,
        agreement: false,
        captcha: false,
        interactiveAuths: null,
      );
    case ResetSession:
      return AuthStore(
        loading: false,
        user: state.user,
        authObserver: state.authObserver,
        contextObserver: state.contextObserver,
        availableUsers: state.availableUsers,
        clientSecret: state.clientSecret,
      );
    case ResetAuthStore:
      // retain the app sessions auth observer only
      return AuthStore(
        authObserver: state.authObserver,
        contextObserver: state.contextObserver,
        availableUsers: state.availableUsers,
        clientSecret: state.clientSecret,
      );
    default:
      return state;
  }
}

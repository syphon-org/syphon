import 'package:syphon/store/auth/context/actions.dart';

import '../user/model.dart';
import './actions.dart';
import './state.dart';

AuthStore authReducer([AuthStore state = const AuthStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetCreating:
      return state.copyWith(creating: action.creating);
    case SetAuthObserver:
      return state.copyWith(authObserver: action.authObserver);
    case SetContextObserver:
      return state.copyWith(contextObserver: action.contextObserver);
    case SetUser:
      final _action = action as SetUser;
      final availableUsers = List<User>.from(state.availableUsers);
      final hasUser = availableUsers.indexWhere(
        (user) => user.userId == _action.user.userId,
      );

      if (hasUser != -1) {
        availableUsers.replaceRange(hasUser, hasUser + 1, [
          _action.user.copyWith(accessToken: ''),
        ]);
      }

      return state.copyWith(
        user: _action.user,
        availableUsers: availableUsers,
      );
    case SetSession:
      return state.copyWith(session: action.session);
    case SetClientSecret:
      return state.copyWith(clientSecret: action.clientSecret);
    case SetCompleted:
      return state.copyWith(completed: action.completed);
    case SetCredential:
      return state.copyWith(credential: action.credential);
    case SetInteractiveAuths:
      return state.copyWith(interactiveAuths: action.interactiveAuths);
    case SetHostname:
      return state.copyWith(hostname: action.hostname);
    case SetHomeserver:
      return state.copyWith(homeserver: action.homeserver);
    case SetUsername:
      return state.copyWith(username: action.username);
    case SetUsernameValid:
      return state.copyWith(isUsernameValid: action.valid);
    case SetUsernameAvailability:
      return state.copyWith(isUsernameAvailable: action.availability);
    case SetPassword:
      return state.copyWith(password: action.password);
    case SetPasswordConfirm:
      return state.copyWith(passwordConfirm: action.password);
    case SetPasswordCurrent:
      return state.copyWith(passwordCurrent: action.password);
    case SetPasswordValid:
      return state.copyWith(isPasswordValid: action.valid);
    case SetEmail:
      return state.copyWith(email: action.email);
    case SetEmailValid:
      return state.copyWith(isEmailValid: action.valid);
    case SetEmailAvailability:
      return state.copyWith(isEmailAvailable: action.available);
    case SetVerificationNeeded:
      return state.copyWith(verificationNeeded: action.needed);
    case SetCaptcha:
      return state.copyWith(captcha: action.completed);
    case SetAgreement:
      return state.copyWith(agreement: action.agreement);
    case AddAvailableUser:
      final _action = action as AddAvailableUser;
      final availableUser = _action.availableUser;
      final availableUsers = List<User>.from(state.availableUsers);

      final existingIndex = availableUsers.indexWhere((user) => user.userId == availableUser.userId);

      if (existingIndex == -1) {
        availableUsers.add(availableUser);
      }

      return state.copyWith(availableUsers: availableUsers);
    case RemoveAvailableUser:
      final _action = action as RemoveAvailableUser;
      final availableUser = _action.availableUser;
      final availableUsers = List<User>.from(state.availableUsers);

      final existingIndex = availableUsers.indexWhere((user) => user.userId == availableUser.userId);

      if (existingIndex != -1) {
        availableUsers.remove(availableUser);
      }

      return state.copyWith(availableUsers: availableUsers);
    case ResetUser:
      return state.copyWith(user: User());
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

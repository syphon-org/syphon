// Project imports:
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
    case SetUser:
      return state.copyWith(user: action.user);
    case SetSession:
      return state.copyWith(session: action.session);
    case SetCompleted:
      return state.copyWith(completed: action.completed);
    case SetCredential:
      return state.copyWith(credential: action.credential);
    case SetInteractiveAuths:
      return state.copyWith(
        interactiveAuths: action.interactiveAuths,
      );
    case SetHomeserver:
      return state.copyWith(homeserver: action.homeserver);
    case SetHomeserverValid:
      return state.copyWith(isHomeserverValid: action.valid);
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
    case ResetUser:
      return state.copyWith(user: User());
    case ResetOnboarding:
      return state.copyWith(
        username: '',
        password: null,
        passwordConfirm: null,
        passwordCurrent: null,
        isPasswordValid: false,
        isUsernameValid: false,
        agreement: false,
        captcha: false,
        interactiveAuths: null,
      );
    case ResetAuthStore:
      return AuthStore();
    default:
      return state;
  }
}

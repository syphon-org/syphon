import './state.dart';
import './actions.dart';
import '../user/model.dart';

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
    case SetPasswordValid:
      return state.copyWith(isPasswordValid: action.valid);
    case ResetUser:
      return state.copyWith(user: User());
    case ResetOnboarding:
      return state.copyWith(
        username: '',
        password: '',
        homeserver: '',
      );
    default:
      return state;
  }
}

import './model.dart';
import './actions.dart';

UserStore userReducer([UserStore state = const UserStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetCreating:
      return state.copyWith(creating: action.creating);
    case SetUser:
      return state.copyWith(user: action.user);
    case SetHomeserver:
      return state.copyWith(
        homeserver: action.homeserver,
      );
    case SetHomeserverValid:
      return state.copyWith(
        isHomeserverValid: action.valid,
      );
    case SetUsername:
      return state.copyWith(
        username: action.username,
      );
    case SetUsernameValid:
      return state.copyWith(
        isUsernameValid: action.valid,
      );
    case SetPassword:
      return state.copyWith(
        password: action.password,
      );
    case SetPasswordValid:
      return state.copyWith(
        isPasswordValid: action.valid,
      );
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

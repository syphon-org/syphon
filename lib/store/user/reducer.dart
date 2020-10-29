// Project imports:
import './actions.dart';
import './model.dart';
import './state.dart';

UserStore userReducer([UserStore state = const UserStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetUserInvites:
      return state.copyWith(invites: action.users);
    case ClearUserInvites:
      return state.copyWith(invites: const []);
    case SetThrottle:
      return state.copyWith(throttle: action.throttle);
    case SetUsers:
      return state.copyWith(users: action.users);
    default:
      return state;
  }
}

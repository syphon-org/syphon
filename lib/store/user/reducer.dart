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
    case SetUsersBlocked:
      return state.copyWith(blocked: action.userIds);
    case SetUsers:
      final users = Map<String, User>.from(state.users);
      users.addAll(action.users);
      return state.copyWith(users: users);
    case SaveUser:
      final user = action.user as User;
      final users = Map<String, User>.from(state.users);

      if (users[user.userId] != null) {
        final existingUser = users[user.userId];
        users[user.userId] = existingUser.copyWith(
          avatarUri: user.avatarUri,
          displayName: user.displayName,
        );
      } else {
        users[user.userId] = user;
      }

      return state.copyWith(users: users);
    case ClearUserInvites:
      return state.copyWith(invites: const []);
    default:
      return state;
  }
}

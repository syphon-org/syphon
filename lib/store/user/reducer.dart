// Project imports:
import './actions.dart';
import './model.dart';
import './state.dart';

UsersStore userReducer(
    [UsersStore state = const UsersStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
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

      return state.copyWith(users: action.users);
    default:
      return state;
  }
}

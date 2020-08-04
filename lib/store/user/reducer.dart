// Project imports:
import './model.dart';
import './state.dart';

UsersStore userReducer(
    [UsersStore state = const UsersStore(), dynamic action]) {
  switch (action.runtimeType) {
    default:
      return state;
  }
}

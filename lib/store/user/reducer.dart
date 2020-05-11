import './state.dart';
import './model.dart';

UsersStore userReducer(
    [UsersStore state = const UsersStore(), dynamic action]) {
  switch (action.runtimeType) {
    default:
      return state;
  }
}

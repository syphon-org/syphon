import './model.dart';
import './actions.dart';

UserStore userReducer([UserStore state = const UserStore(), dynamic action]) {
  print('User Reducer $action');
  switch (action.runtimeType) {
    case SetLoading:
      return new UserStore(
          loading: action.loading,
          user: new User(
            id: action.id,
            name: action.name,
          ));
    case SetUser:
      return new UserStore(
          loading: state.loading,
          user: new User(
            id: action.id,
            name: action.name,
          ));
    default:
      return state;
  }
}

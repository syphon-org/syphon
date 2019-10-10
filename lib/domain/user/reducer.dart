import './model.dart';

enum Actions { login, logout, setLoading, reset }

UserStore userReducer(UserStore state, action) {
  switch (action.type) {
    case Actions.login:
      return new UserStore(
          loading: false,
          user: new User(
            id: action.id,
            name: action.name,
          ));
    case Actions.logout:
      return new UserStore(
          loading: false,
          user: new User(
            id: action.id,
            name: action.name,
          ));
    case Actions.setLoading:
      return new UserStore(
          loading: action.loading,
          user: new User(
            id: state.user.id,
            name: state.user.name,
          ));
    default:
      return state;
  }
}

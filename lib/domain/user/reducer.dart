import './model.dart';
import './actions.dart';

UserStore userReducer([UserStore state = const UserStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return new UserStore(
          loading: action.loading,
          username: state.username,
          password: state.password,
          homeserver: state.homeserver,
          user: new User(
              id: state.user.id,
              username: state.user.username,
              homeserver: state.user.homeserver));
    case SetUser:
      return new UserStore(
          loading: state.loading,
          username: state.username,
          password: state.password,
          homeserver: state.homeserver,
          user: new User(
            id: action.user.id,
            username: action.user.username,
            homeserver: action.user.homeserver,
          ));
    case SetHomeserver:
      return new UserStore(
          loading: state.loading,
          username: state.username,
          password: state.password,
          homeserver: action.homeserver,
          user: new User(
            id: state.user.id,
            username: state.user.username,
            homeserver: action.user.homeserver,
          ));
    case SetUsername:
      return new UserStore(
          loading: state.loading,
          username: action.username,
          password: state.password,
          homeserver: state.homeserver,
          user: new User(
            id: state.user.id,
            username: state.user.username,
            homeserver: action.user.homeserver,
          ));
    default:
      return state;
  }
}

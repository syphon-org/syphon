import './model.dart';
import './actions.dart';

UserStore userReducer([UserStore state = const UserStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return new UserStore(
          loading: action.loading,
          homeserver: state.homeserver,
          homeservers: state.homeservers,
          searchResults: state.homeservers,
          user: new User(
            id: state.user.id,
            name: state.user.name,
          ));
    case SetUser:
      return new UserStore(
          loading: state.loading,
          homeserver: state.homeserver,
          homeservers: state.homeservers,
          searchResults: state.searchResults,
          user: new User(
            id: action.user.id,
            name: action.user.name,
          ));
    case SetHomeservers:
      return new UserStore(
          loading: state.loading,
          homeserver: state.homeserver,
          homeservers: action.homeservers,
          searchResults: action.homeservers, // also sets search results
          user: new User(
            id: state.user.id,
            name: state.user.name,
          ));
    case SetHomeserver:
      return new UserStore(
          loading: state.loading,
          homeserver: action.homeserver,
          homeservers: state.homeservers,
          searchResults: state.searchResults,
          user: new User(
            id: state.user.id,
            name: state.user.name,
          ));
    case SetSearchResults:
      return new UserStore(
          loading: state.loading,
          homeserver: state.homeserver,
          homeservers: state.homeservers,
          searchResults: action.searchResults,
          user: new User(
            id: state.user.id,
            name: state.user.name,
          ));
    default:
      return state;
  }
}

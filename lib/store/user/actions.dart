import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';

class SetLoading {
  final bool? loading;
  SetLoading({this.loading});
}

class SaveUser {
  final User? user;
  SaveUser({this.user});
}

class SetUsers {
  final Map<String, User>? users;
  SetUsers({this.users});
}

class SetUsersBlocked {
  final List<String?>? userIds;
  SetUsersBlocked({this.userIds});
}

class SetUserInvites {
  final List<User>? users;
  SetUserInvites({this.users});
}

class LoadUsers {
  final List<String>? userIds;
  LoadUsers({this.userIds});
}

class ClearUserInvites {}

class ResetUsers {}

ThunkAction<AppState> setUsers(Map<String, User> users) {
  return (Store<AppState> store) {
    if (users.isEmpty) return;

    store.dispatch(SetUsers(users: users));
  };
}

ThunkAction<AppState> setUsersBlocked(List<String?> userIds) {
  return (Store<AppState> store) {
    store.dispatch(SetUsersBlocked(userIds: userIds));
  };
}

ThunkAction<AppState> setUserInvites({List<User>? users}) {
  return (Store<AppState> store) {
    store.dispatch(SetUserInvites(users: users));
  };
}

ThunkAction<AppState> clearUserInvites() {
  return (Store<AppState> store) {
    store.dispatch(ClearUserInvites());
  };
}

ThunkAction<AppState> fetchUser({User user = const User()}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchUserProfile(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: user.userId,
      );

      store.dispatch(SaveUser(
        user: user.copyWith(
          userId: user.userId,
          avatarUri: data['avatar_url'],
          displayName: data['displayname'],
        ),
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: 'Failed to load users profile',
        origin: 'fetchUserProfile',
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/// Toggle Block User
///
/// Fetch the blocked user list and recalculate
/// events without the given user id
ThunkAction<AppState> toggleBlockUser({User? user = const User()}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // Pull remote direct room data
      final data = await MatrixApi.fetchAccountData(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
        type: AccountDataTypes.ignoredUserList,
      );

      // skip error if there's no blocked users list yet
      if (data['errcode'] != null) {
        if (data['errcode'] != MatrixErrors.not_found) {
          throw data['error'];
        }
      }

      // Pull the direct room for that specific user
      final Map<String, dynamic> usersBlocked = data['ignored_users'] ?? {};

      // toggle based on if the id is already present
      if (!usersBlocked.containsKey(user!.userId)) {
        usersBlocked[user.userId!] = {};
      } else {
        usersBlocked.remove(user.userId);
      }

      // locally track the blocked users list
      final usersBlockedList = usersBlocked.keys.toList();
      await store.dispatch(setUsersBlocked(usersBlockedList));

      // save blocked users list back to account_data remotely
      final saveData = await MatrixApi.updateBlockedUsers(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        userId: store.state.authStore.user.userId,
        blockUserList: usersBlocked,
      );

      if (saveData['errcode'] != null) {
        throw saveData['error'];
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: 'Failed to toggle user on blocklist',
        origin: 'toggleBlockUser',
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

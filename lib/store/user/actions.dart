// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

/**
 * TODO: Create one store for all known users
 */

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SaveUser {
  final User user;
  SaveUser({this.user});
}

class SetUserInvites {
  final List<User> users;
  SetUserInvites({this.users});
}

class ClearUserInvites {}

ThunkAction<AppState> setUserInvites({List<User> users}) {
  return (Store<AppState> store) async {
    store.dispatch(SetUserInvites(users: users));
  };
}

ThunkAction<AppState> clearUserInvites() {
  return (Store<AppState> store) async {
    store.dispatch(ClearUserInvites());
  };
}

ThunkAction<AppState> fetchUserProfile({User user}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchUserProfile(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.currentUser.userId,
      );

      store.dispatch(SaveUser(
        user: user.copyWith(
          displayName: data['displayname'],
          avatarUri: data['avatar_url'],
        ),
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: "Failed to load users profile",
        origin: 'fetchUserProfile',
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Toggle Direct Room
 * 
 * NOTE: https://github.com/matrix-org/matrix-doc/issues/1519
 * 
 * Fetch the direct rooms list and recalculate it without the
 * given alias
 */
ThunkAction<AppState> toggleBlockUser({User user, Room room, bool block}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // Pull remote direct room data
      final data = await MatrixApi.fetchAccountData(
          protocol: protocol,
          homeserver: store.state.authStore.user.homeserver,
          accessToken: store.state.authStore.user.accessToken,
          userId: store.state.authStore.user.userId,
          type: AccountDataTypes.ignoredUserList);

      if (data['errcode'] != null) {
        throw data['error'];
      }

      return false;

      // Pull the direct room for that specific user
      Map directRoomUsers = data as Map<String, dynamic>;
      final usersDirectRooms = directRoomUsers[user] ?? [];

      if (usersDirectRooms.isEmpty && block) {
        directRoomUsers[user.userId] = [room.id];
      }

      // Toggle the direct room data based on user actions
      directRoomUsers = directRoomUsers.map((userId, rooms) {
        List<dynamic> updatedRooms = List.from(rooms ?? []);

        if (userId != user.userId) {
          return MapEntry(userId, updatedRooms);
        }

        if (block) {
          updatedRooms.add(room.id);
        } else {
          updatedRooms.removeWhere((roomId) => roomId == room.id);
        }

        return MapEntry(userId, updatedRooms);
      });

      // Filter out empty list entries for a user
      directRoomUsers.removeWhere((key, value) {
        final roomIds = value ?? [];
        return roomIds.isEmpty;
      });

      final saveData = await MatrixApi.saveAccountData(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        userId: store.state.authStore.user.userId,
        type: AccountDataTypes.ignoredUserList,
        accountData: directRoomUsers,
      );

      if (saveData['errcode'] != null) {
        throw saveData['error'];
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: "Failed to load users profile",
        origin: 'fetchUserProfile',
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

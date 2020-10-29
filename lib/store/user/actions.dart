// Package imports:
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/cache/threadables.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetUsers {
  final Map<String, User> users;

  SetUsers({this.users});
}

class SetUserInvites {
  final List<User> users;
  SetUserInvites({this.users});
}

class SetThrottle {
  final DateTime throttle;
  SetThrottle({this.throttle});
}

class ClearUserInvites {}

/**
 * Sync Users w/ Storage
 * 
 * 
 */
ThunkAction<AppState> syncUsers(Map<String, User> usersFound) {
  return (Store<AppState> store) async {
    final throttle = store.state.userStore.throttle;
    final usersKnown = Map<String, User>.from(store.state.userStore.users);
    final usersKnownLength = usersKnown.length;

    // add all users found in the event list to the array
    usersKnown.addAll(usersFound);

    // skip if all known users amount has not changed
    if (usersKnown.length == usersKnownLength || usersKnown.isEmpty) return;

    debugPrint('[syncUsers] TOTAL USERS ${usersKnown.length}');

    // otherwise update the user hot cache
    store.dispatch(SetUsers(users: usersKnown));

    if (throttle != null) {
      debugPrint(
        '[syncUsers] THROTTLE DIFFERENCE ${throttle.difference(DateTime.now()).toString()}',
      );
    }

    // skip caching if a user cache has occured within the last 4 seconds
    if (throttle != null &&
        DateTime.now().difference(throttle) < Duration(seconds: 4)) return;

    debugPrint('[syncUsers] CACHING USERS ${usersKnown.length}');

    // set new throttle
    store.dispatch(SetThrottle(throttle: DateTime.now()));

    // and save to cold cache
    await Future.microtask(() async {
      try {
        // /create a new IV for the encrypted cache
        CacheSecure.ivKeyUsers = createIVKey();

        // backup the IV in case the app is force closed before caching finishes
        await saveIVKey(
          CacheSecure.ivKeyUsers,
          ivKeyLocation: CacheSecure.ivKeyUsersNextLocation,
        );

        final jsonEncoded = json.encode(usersKnown);

        // encrypt the json payload
        final jsonEncrypted = await compute(encryptJsonBackground, {
          'ivKey': CacheSecure.ivKeyUsers,
          'cryptKey': CacheSecure.cryptKey,
          'type': store.runtimeType.toString(),
          'json': jsonEncoded,
        });

        // save encrypted user cache
        await CacheSecure.cacheUsers.put(
          CacheSecure.cacheKeyUsers,
          jsonEncrypted,
        );

        // save IVKey as most recently successful encryption I
        await saveIVKey(
          CacheSecure.ivKeyUsers,
          ivKeyLocation: CacheSecure.ivKeyUsersLocation,
        );
      } catch (error) {
        debugPrint('[syncUsers] $error');
      }
    });
  };
}

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

// ThunkAction<AppState> fetchUserProfile({User user}) {
//   return (Store<AppState> store) async {
//     try {
//       store.dispatch(SetLoading(loading: true));

//       final data = await MatrixApi.fetchUserProfile(
//         protocol: protocol,
//         homeserver: store.state.authStore.user.homeserver,
//         accessToken: store.state.authStore.user.accessToken,
//         userId: store.state.authStore.currentUser.userId,
//       );

//       store.dispatch(SaveUsers(
//         user: user.copyWith(
//           displayName: data['displayname'],
//           avatarUri: data['avatar_url'],
//         ),
//       ));
//     } catch (error) {
//       store.dispatch(addAlert(
//         error: error,
//         message: "Failed to load users profile",
//         origin: 'fetchUserProfile',
//       ));
//     } finally {
//       store.dispatch(SetLoading(loading: false));
//     }
//   };
// }

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

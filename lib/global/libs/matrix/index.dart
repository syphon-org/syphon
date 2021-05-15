// Project imports:
import 'dart:async';

import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/devices.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/events.dart';
import 'package:syphon/global/libs/matrix/media.dart';
import 'package:syphon/global/libs/matrix/notifications.dart';
import 'package:syphon/global/libs/matrix/rooms.dart';
import 'package:syphon/global/libs/matrix/search.dart';
import 'package:syphon/global/libs/matrix/user.dart';

abstract class MatrixApi {
  static const NEEDS_INTERACTIVE_AUTH = Auth.NEEDS_INTERACTIVE_AUTH;

  // Auth
  static final loginUser = Auth.loginUser;
  static final loginUserToken = Auth.loginUserToken;
  static final loginType = Auth.loginType;
  static final logoutUser = Auth.logoutUser;
  static final registerUser = Auth.registerUser;
  static final registerEmail = Auth.registerEmail;
  static final resetPassword = Auth.resetPassword;
  static final updatePassword = Auth.updatePassword;
  static final checkUsernameAvailability = Auth.checkUsernameAvailability;
  static final sendPasswordResetEmail = Auth.sendPasswordResetEmail;
  static final checkHomeserver = Auth.checkHomeserver;
  static final checkVersion = Auth.checkVersion;

  // Search
  static final searchRooms = Search.searchRooms;
  static final searchUsers = Search.searchUsers;

  // Rooms
  static final sync = Rooms.sync;
  static final syncRoom = Rooms.syncRoom;
  static final syncBackground = Rooms.syncBackground;
  static final fetchRoomIds = Rooms.fetchRoomIds;
  static final fetchDirectRoomIds = Rooms.fetchDirectRoomIds;
  static final createRoom = Rooms.createRoom;
  static final joinRoom = Rooms.joinRoom;
  static final leaveRoom = Rooms.leaveRoom;
  static final forgetRoom = Rooms.forgetRoom;
  static final fetchFilter = Rooms.fetchFilter;
  static final createFilter = Rooms.createFilter;

  // Events
  static final sendEvent = Events.sendEvent;
  static final sendTyping = Events.sendTyping;
  static final sendMessage = Events.sendMessage;
  static final sendReaction = Events.sendReaction;
  static final sendReadReceipts = Events.sendReadMarkers;
  static final sendEventToDevice = Events.sendEventToDevice;
  static final sendMessageEncrypted = Events.sendMessageEncrypted;
  static final fetchStateEvents = Events.fetchStateEvents;
  static final fetchMessageEvents = Events.fetchMessageEvents;
  static final fetchMessageEventsMapped = Events.fetchMessageEventsMapped;
  static final redactEvent = Events.redactEvent;

  // Account Data & User Management
  static final fetchAccountData = Users.fetchAccountData;
  static final saveAccountData = Users.saveAccountData;
  static final updateDisplayName = Users.updateDisplayName;
  static final updateAvatarUri = Users.updateAvatarUri;

  // Users
  static final inviteUser = Users.inviteUser;
  static final fetchUserProfile = Users.fetchUserProfile;
  static final updateBlockedUsers = Users.updateBlockedUsers;

  // Media
  static final fetchThumbnail = Media.fetchThumbnail;
  static final uploadMedia = Media.uploadMedia;

  // Device Management
  static final fetchDevices = Devices.fetchDevices;
  static final updateDevice = Devices.updateDevice;
  static final deleteDevice = Devices.deleteDevice;
  static final deleteDevices = Devices.deleteDevices;

  // Keys
  static final fetchKeys = Encryption.fetchKeys;
  static final fetchKeyChanges = Encryption.fetchKeyChanges;
  static final claimKeys = Encryption.claimKeys;
  static final uploadKeys = Encryption.uploadKeys;

  // Notifications
  static final fetchNotifications = Notifications.fetchNotifications;
  static final fetchNotificationPushers =
      Notifications.fetchNotificationPushers;

  /**
   * Save Notification Pusher
   * 
   * https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-pushers
   * 
   * This endpoint allows the creation, modification and deletion of pushers for 
   * this user ID. The behaviour of this endpoint varies depending on the values 
   * in the JSON body.
   */
  static final saveNotificationPusher = Notifications.saveNotificationPusher;
}

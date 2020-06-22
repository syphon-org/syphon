import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/devices.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/events.dart';
import 'package:syphon/global/libs/matrix/notifications.dart';
import 'package:syphon/global/libs/matrix/rooms.dart';
import 'package:syphon/global/libs/matrix/user.dart';

abstract class MatrixApi {
  // Authentication
  static const NEEDS_INTERACTIVE_AUTH = Auth.NEEDS_INTERACTIVE_AUTH;

  static final loginUser = Auth.loginUser;
  static final logoutUser = Auth.logoutUser;
  static final registerUser = Auth.registerUser;
  static final updatePassword = Auth.updatePassword;
  static final checkUsernameAvailability = Auth.checkUsernameAvailability;

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

  // Events
  static final sendEvent = Events.sendEvent;
  static final sendTyping = Events.sendTyping;
  static final sendMessage = Events.sendMessage;
  static final sendMessageEncrypted = Events.sendMessageEncrypted;
  static final fetchStateEvents = Events.fetchStateEvents;
  static final fetchMessageEvents = Events.fetchMessageEvents;
  static final sendEventToDevice = Events.sendEventToDevice;

  // Account Data & User Management
  static final fetchAccountData = Users.fetchAccountData;
  static final saveAccountData = Users.saveAccountData;
  static final fetchUserProfile = Users.fetchUserProfile;
  static final updateDisplayName = Users.updateDisplayName;
  static final updateAvatarUri = Users.updateAvatarUri;

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

import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/global/libs/matrix/devices.dart';
import 'package:Tether/global/libs/matrix/events.dart';
import 'package:Tether/global/libs/matrix/notifications.dart';
import 'package:Tether/global/libs/matrix/rooms.dart';
import 'package:Tether/global/libs/matrix/user.dart';

abstract class MatrixApi {
  // Authentication
  static const NEEDS_INTERACTIVE_AUTH = Auth.NEEDS_INTERACTIVE_AUTH;

  static final loginUser = Auth.loginUser;
  static final logoutUser = Auth.logoutUser;
  static final registerUser = Auth.registerUser;
  static final checkUsernameAvailability = Auth.checkUsernameAvailability;

  // Rooms
  static final sync = Rooms.sync;
  static final syncRoom = Rooms.syncRoom;
  static final syncBackground = Rooms.syncBackground;
  static final fetchRoomIds = Rooms.fetchRoomIds;
  static final fetchDirectRoomIds = Rooms.fetchDirectRoomIds;
  static final createRoom = Rooms.createRoom;
  static final leaveRoom = Rooms.leaveRoom;
  static final forgetRoom = Rooms.forgetRoom;

  // Events
  static final fetchStateEvents = Events.fetchStateEvents;
  static final fetchMessageEvents = Events.fetchMessageEvents;
  static final sendMessage = Events.sendMessage;
  static final sendTyping = Events.sendTyping;

  /*** Users ***/

  /**
   * Save Account Data
   * 
   * https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-user-userid-account-data-type
   * 
   * Set some account_data for the client. This config is only visible
   * to the user that set the account_data. The config will be synced 
   * to clients in the top-level account_data.
   */
  static final fetchAccountData = Users.fetchAccountData;
  static final saveAccountData = Users.saveAccountData;

  // Device Management
  static final fetchDevices = Devices.fetchDevices;
  static final updateDevice = Devices.updateDevice;
  static final deleteDevice = Devices.deleteDevice;
  static final deleteDevices = Devices.deleteDevices;

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

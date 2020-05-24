import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/global/libs/matrix/devices.dart';
import 'package:Tether/global/libs/matrix/events.dart';
import 'package:Tether/global/libs/matrix/notifications.dart';
import 'package:Tether/global/libs/matrix/rooms.dart';

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

  // Events
  static final fetchStateEvents = Events.fetchStateEvents;
  static final fetchMessageEvents = Events.fetchMessageEvents;
  static final sendMessage = Events.sendMessage;
  static final sendTyping = Events.sendTyping;

  // Device Management
  static final fetchDevices = Devices.fetchDevices;
  static final updateDevice = Devices.updateDevice;
  static final deleteDevice = Devices.deleteDevice;
  static final deleteDevices = Devices.deleteDevices;

  // Notifications
  static final fetchNotifications = Notifications.fetchNotifications;
  static final fetchNotificationPushers =
      Notifications.fetchNotificationPushers;
  static final saveNotificationPushers = Notifications.saveNotificationPusher;
}

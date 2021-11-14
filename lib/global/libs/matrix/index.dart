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
  static const loginUser = Auth.loginUser;
  static const loginUserToken = Auth.loginUserToken;
  static const loginType = Auth.loginType;
  static const logoutUser = Auth.logoutUser;
  static const registerUser = Auth.registerUser;
  static const registerEmail = Auth.registerEmail;
  static const resetPassword = Auth.resetPassword;
  static const updatePassword = Auth.updatePassword;
  static const checkUsernameAvailability = Auth.checkUsernameAvailability;
  static const sendPasswordResetEmail = Auth.sendPasswordResetEmail;
  static const checkHomeserver = Auth.checkHomeserver;
  static const checkHomeserverAlt = Auth.checkHomeserverAlt;
  static const checkVersion = Auth.checkVersion;

  // Search
  static const searchRooms = Search.searchRooms;
  static const searchUsers = Search.searchUsers;

  // Rooms
  static const sync = Rooms.sync;
  static const syncRoom = Rooms.syncRoom;
  static const syncThreaded = Rooms.syncThreaded;
  static const fetchRoomIds = Rooms.fetchRoomIds;
  static const fetchRoomName = Rooms.fetchRoomName;
  static const fetchDirectRoomIds = Rooms.fetchDirectRoomIds;
  static const fetchMembersAll = Rooms.fetchMembersAll;
  static const createRoom = Rooms.createRoom;
  static const joinRoom = Rooms.joinRoom;
  static const leaveRoom = Rooms.leaveRoom;
  static const forgetRoom = Rooms.forgetRoom;
  static const fetchFilter = Rooms.fetchFilter;
  static const createFilter = Rooms.createFilter;
  static const fetchPowerLevels = Rooms.fetchPowerLevels;

  // Events
  static const sendEvent = Events.sendEvent;
  static const sendTyping = Events.sendTyping;
  static const sendMessage = Events.sendMessage;
  static const sendReaction = Events.sendReaction;
  static const sendReadReceipts = Events.sendReadMarkers;
  static const sendEventToDevice = Events.sendEventToDevice;
  static const sendMessageEncrypted = Events.sendMessageEncrypted;
  static const fetchStateEvents = Events.fetchStateEvents;
  static const fetchMessageEvents = Events.fetchMessageEvents;
  static const fetchMessageEventsThreaded = Events.fetchMessageEventsThreaded;
  static const redactEvent = Events.redactEvent;
  static const deleteMessage = Events.deleteMessage;

  // Account Data & User Management
  static const fetchAccountData = Users.fetchAccountData;
  static const saveAccountData = Users.saveAccountData;
  static const updateDisplayName = Users.updateDisplayName;
  static const updateAvatarUri = Users.updateAvatarUri;
  static const deactivateUser = Users.deactivateUser;

  // Users
  static const inviteUser = Users.inviteUser;
  static const fetchUserProfile = Users.fetchUserProfile;
  static const updateBlockedUsers = Users.updateBlockedUsers;

  // Media
  static const fetchMedia = MatrixMedia.fetchMedia;
  static const uploadMedia = MatrixMedia.uploadMedia;
  static const fetchMediaThreaded = MatrixMedia.fetchMediaThreaded;
  static const fetchThumbnailThreaded = MatrixMedia.fetchThumbnailThreaded;

  // Device Management
  static const fetchDevices = Devices.fetchDevices;
  static const updateDevice = Devices.updateDevice;
  static const deleteDevices = Devices.deleteDevices;
  static const renameDevice = Devices.renameDevice;

  // Keys
  static const fetchKeys = Encryption.fetchKeys;
  static const fetchKeyChanges = Encryption.fetchKeyChanges;
  static const claimKeys = Encryption.claimKeys;
  static const uploadKeys = Encryption.uploadKeys;
  static const requestKeys = Encryption.requestKeys;

  // Notifications
  static const fetchNotifications = Notifications.fetchNotifications;
  static const fetchNotificationPushers = Notifications.fetchNotificationPushers;

  /// Save Notification Pusher
  ///
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-pushers
  ///
  /// This endpoint allows the creation, modification and deletion of pushers for
  /// this user ID. The behaviour of this endpoint varies depending on the values
  /// in the JSON body.
  ///
  static const saveNotificationPusher = Notifications.saveNotificationPusher;
}

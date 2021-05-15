// Project imports:
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
  static final FutureOr<dynamic> Function({String? deviceId, String? deviceName, String? homeserver, String password, String? protocol, String type, String username}) loginUser = Auth.loginUser;
  static final FutureOr<dynamic> Function({String? deviceId, String? deviceName, String? homeserver, String? protocol, String? session, String token, String type}) loginUserToken = Auth.loginUserToken;
  static final loginType = Auth.loginType;
  static final Future<dynamic> Function({String accessToken, String? homeserver, String? protocol}) logoutUser = Auth.logoutUser;
  static final FutureOr<dynamic> Function({Map<dynamic, dynamic>? authParams, String? authType, String? authValue, String? deviceId, String? deviceName, String? homeserver, String password, String? protocol, String? session, String username}) registerUser = Auth.registerUser;
  static final FutureOr<dynamic> Function({String? clientSecret, String email, String? homeserver, String? protocol, int? sendAttempt}) registerEmail = Auth.registerEmail;
  static final resetPassword = Auth.resetPassword;
  static final FutureOr<dynamic> Function({String? accessToken, String currentPassword, String? homeserver, String password, String? protocol, String? session, String type, String? userId}) updatePassword = Auth.updatePassword;
  static final Future<dynamic> Function({String? homeserver, String? protocol, String username}) checkUsernameAvailability = Auth.checkUsernameAvailability;
  static final FutureOr<dynamic> Function({String? clientSecret, String email, String? homeserver, String? protocol, int sendAttempt}) sendPasswordResetEmail = Auth.sendPasswordResetEmail;
  static final checkHomeserver = Auth.checkHomeserver;
  static final checkVersion = Auth.checkVersion;

  // Search
  static final FutureOr<dynamic> Function({String? accessToken, bool global, String? homeserver, String? protocol, String searchText, String? server, String since}) searchRooms = Search.searchRooms;
  static final FutureOr<dynamic> Function({String? accessToken, String? homeserver, String? protocol, String? searchText, String since}) searchUsers = Search.searchUsers;

  // Rooms
  static final Future<dynamic> Function({String accessToken, String filter, bool fullState, String? homeserver, String? protocol, String setPresence, String since, int timeout}) sync = Rooms.sync;
  static final Future<dynamic> Function({String accessToken, String homeserver, String protocol, String roomId, String since}) syncRoom = Rooms.syncRoom;
  static final syncBackground = Rooms.syncBackground;
  static final Future<dynamic> Function({String? accessToken, String? homeserver, String? protocol, String userId}) fetchRoomIds = Rooms.fetchRoomIds;
  static final fetchDirectRoomIds = Rooms.fetchDirectRoomIds;
  static final createRoom = Rooms.createRoom;
  static final joinRoom = Rooms.joinRoom;
  static final leaveRoom = Rooms.leaveRoom;
  static final forgetRoom = Rooms.forgetRoom;
  static final Future<dynamic> Function({String accessToken, String filterId, String homeserver, String protocol, String roomAlias, String userId}) fetchFilter = Rooms.fetchFilter;
  static final Future<dynamic> Function({String accessToken, Map<dynamic, dynamic> filters, String homeserver, bool lazyLoading, String protocol, String userId}) createFilter = Rooms.createFilter;

  // Events
  static final Future<dynamic> Function({String? accessToken, Map<dynamic, dynamic> content, String eventType, String? homeserver, String? protocol, String? roomId, String stateKey}) sendEvent = Events.sendEvent;
  static final sendTyping = Events.sendTyping;
  static final Future<dynamic> Function({String? accessToken, String? homeserver, Map<dynamic, dynamic>? message, String? protocol, String? roomId, String trxId}) sendMessage = Events.sendMessage;
  static final Future<dynamic> Function({String? accessToken, String? homeserver, String? messageId, String protocol, String? reaction, String? roomId, String trxId}) sendReaction = Events.sendReaction;
  static final Future<dynamic> Function({String? accessToken, String? homeserver, String lastRead, String? messageId, String? protocol, bool readAll, String? roomId}) sendReadReceipts = Events.sendReadMarkers;
  static final Future<dynamic> Function({String? accessToken, Map<dynamic, dynamic> content, String deviceId, String eventType, String? homeserver, String? protocol, String trxId, String userId}) sendEventToDevice = Events.sendEventToDevice;
  static final Future<dynamic> Function({String? accessToken, String? ciphertext, String? deviceId, String? homeserver, String? protocol, String? roomId, String? senderKey, String? sessionId, String trxId, Map<dynamic, dynamic> unencryptedData}) sendMessageEncrypted = Events.sendMessageEncrypted;
  static final fetchStateEvents = Events.fetchStateEvents;
  static final Future<dynamic> Function({String accessToken, bool desc, String from, String homeserver, int limit, String protocol, String roomId, String to}) fetchMessageEvents = Events.fetchMessageEvents;
  static final fetchMessageEventsMapped = Events.fetchMessageEventsMapped;
  static final Future<dynamic> Function({String? accessToken, String? eventId, String? homeserver, String protocol, String? roomId, String trxId}) redactEvent = Events.redactEvent;

  // Account Data & User Management
  static final fetchAccountData = Users.fetchAccountData;
  static final Future<dynamic> Function({String? accessToken, Map<dynamic, dynamic> accountData, String? homeserver, String? protocol, String type, String? userId}) saveAccountData = Users.saveAccountData;
  static final Future<dynamic> Function({String? accessToken, Map<dynamic, dynamic> accountData, String displayName, String? homeserver, String? protocol, String? userId}) updateDisplayName = Users.updateDisplayName;
  static final updateAvatarUri = Users.updateAvatarUri;

  // Users
  static final inviteUser = Users.inviteUser;
  static final fetchUserProfile = Users.fetchUserProfile;
  static final updateBlockedUsers = Users.updateBlockedUsers;

  // Media
  static final fetchThumbnail = Media.fetchThumbnail;
  static final Future<dynamic> Function({String? accessToken, int fileLength, String fileName, Stream<List<int>> fileStream, String fileType, String? homeserver, String? protocol}) uploadMedia = Media.uploadMedia;

  // Device Management
  static final fetchDevices = Devices.fetchDevices;
  static final FutureOr<dynamic> Function({String? accessToken, String deviceId, String displayName, String? homeserver, String? protocol}) updateDevice = Devices.updateDevice;
  static final FutureOr<dynamic> Function({String accessToken, String authType, String authValue, String deviceId, String homeserver, String protocol, String session, String userId}) deleteDevice = Devices.deleteDevice;
  static final FutureOr<dynamic> Function({String? accessToken, String authType, String? authValue, List<String?>? deviceIds, String? homeserver, String? protocol, String? session, String? userId}) deleteDevices = Devices.deleteDevices;

  // Keys
  static final fetchKeys = Encryption.fetchKeys;
  static final Future<dynamic> Function({String accessToken, String from, String homeserver, String protocol, String to}) fetchKeyChanges = Encryption.fetchKeyChanges;
  static final Future<dynamic> Function({String? accessToken, String? homeserver, Map<dynamic, dynamic> oneTimeKeys, String? protocol}) claimKeys = Encryption.claimKeys;
  static final Future<dynamic> Function({String? accessToken, Map<dynamic, dynamic> data, String? homeserver, String? protocol}) uploadKeys = Encryption.uploadKeys;

  // Notifications
  static final Future<dynamic> Function({String? accessToken, String from, String? homeserver, int limit, String only, String? protocol}) fetchNotifications = Notifications.fetchNotifications;
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
  static final Future<dynamic> Function({String? accessToken, String appDisplayName, String appId, String append, String dataUrl, String? deviceDisplayName, String? homeserver, String? kind, String lang, String profileTag, String? protocol, String? pushKey}) saveNotificationPusher = Notifications.saveNotificationPusher;
}

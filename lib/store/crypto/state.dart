import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:olm/olm.dart';
import 'package:syphon/global/print.dart';

import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/sessions/model.dart';

part 'state.g.dart';

@JsonSerializable()
class CryptoStore extends Equatable {
  // Active olm account (loaded from olmAccountKey)
  @JsonKey(ignore: true)
  final Account? olmAccount;

  // Serialized olm account
  final String? olmAccountKey;

  final bool? deviceKeysExist;
  final bool deviceKeyVerified;
  final bool oneTimeKeysStable;

  // TODO: Map<identityKey, Map<SessionId, serializedSession>
  final Map<String, Map<String, String>> keySessions; // both olm inbound and outbound key sessions

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - index per chat
  @Deprecated('switch to using "index" inside MessageSession within inboundMessageSessionsAll')
  final Map<String, Map<String, int>> messageSessionIndex;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - messages per chat
  @Deprecated('switch to inboundMessageSessionsAll to include old session for a device')
  final Map<String, Map<String, String>> inboundMessageSessions;

  // Map<roomId, serializedSession> // megolm - messages
  final Map<String, String> outboundMessageSessions;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - messages per chat
  final Map<String, Map<String, List<MessageSession>>> messageSessionsInbound;

  /// Map<UserId, Map<DeviceId, DeviceKey> deviceKeys
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  // Map<DeviceId, DeviceKey> deviceKeysOwned
  final Map<String, DeviceKey> deviceKeysOwned; // key is deviceId

  // Track last known uploaded key amounts
  final Map<String, int> oneTimeKeysCounts;

  // Track last claimed key amounts
  final Map<String, OneTimeKey> oneTimeKeysClaimed;

  const CryptoStore({
    this.olmAccount,
    this.olmAccountKey,
    this.deviceKeysExist = false,
    this.deviceKeyVerified = false,
    this.oneTimeKeysStable = true,
    this.inboundMessageSessions = const {}, // Megolm Sessions
    this.messageSessionsInbound = const {}, // Megolm Sessions
    this.outboundMessageSessions = const {}, // Megolm Sessions
    this.keySessions = const {}, // Olm sessions
    this.messageSessionIndex = const {},
    this.deviceKeys = const {},
    this.deviceKeysOwned = const {},
    this.oneTimeKeysClaimed = const {},
    this.oneTimeKeysCounts = const {},
  });

  @override
  List<Object?> get props => [
        olmAccount,
        olmAccountKey,
        deviceKeysExist,
        deviceKeyVerified,
        oneTimeKeysStable,
        messageSessionsInbound,
        outboundMessageSessions,
        keySessions,
        deviceKeys,
        deviceKeysOwned,
        oneTimeKeysClaimed,
        oneTimeKeysCounts
      ];

  CryptoStore copyWith({
    Account? olmAccount,
    String? olmAccountKey,
    bool? deviceKeysExist,
    bool? deviceKeyVerified,
    bool? oneTimeKeysStable,
    @Deprecated('only for converting') Map<String, Map<String, int>>? messageSessionIndex,
    @Deprecated('only for converting') Map<String, Map<String, String>>? inboundMessageSessions,
    Map<String, Map<String, List<MessageSession>>>? messageSessionsInbound,
    Map<String, String>? outboundMessageSessions,
    Map<String, Map<String, String>>? keySessions,
    Map<String, DeviceKey>? deviceKeysOwned,
    Map<String, Map<String, DeviceKey>>? deviceKeys,
    Map<String, OneTimeKey>? oneTimeKeysClaimed,
    Map<String, int>? oneTimeKeysCounts,
  }) =>
      CryptoStore(
        olmAccount: olmAccount ?? this.olmAccount,
        olmAccountKey: olmAccountKey ?? this.olmAccountKey,
        messageSessionIndex: messageSessionIndex ?? this.messageSessionIndex,
        inboundMessageSessions: inboundMessageSessions ?? this.inboundMessageSessions,
        messageSessionsInbound: messageSessionsInbound ?? this.messageSessionsInbound,
        outboundMessageSessions: outboundMessageSessions ?? this.outboundMessageSessions,
        keySessions: keySessions ?? this.keySessions,
        deviceKeys: deviceKeys ?? this.deviceKeys,
        deviceKeysOwned: deviceKeysOwned ?? this.deviceKeysOwned,
        oneTimeKeysClaimed: oneTimeKeysClaimed ?? this.oneTimeKeysClaimed,
        deviceKeysExist: deviceKeysExist ?? this.deviceKeysExist,
        deviceKeyVerified: deviceKeyVerified ?? this.deviceKeyVerified,
        oneTimeKeysStable: oneTimeKeysStable ?? this.oneTimeKeysStable,
        oneTimeKeysCounts: oneTimeKeysCounts ?? this.oneTimeKeysCounts,
      );

  // TODO: remove after 0.2.9 release
  // @Deprecated('only use to migrate keys from < 0.2.8 to 0.2.9')
  CryptoStore upgradeSessions_temp() {
    if (inboundMessageSessions.isEmpty) {
      return this;
    }

    log.warn('[upgradeSessions_temp] UPGRADING PREVIOUS KEY SESSIONS');

    final messageSessionsUpdated = Map<String, Map<String, List<MessageSession>>>.from(
      messageSessionsInbound,
    );

    for (final roomSessions in inboundMessageSessions.entries) {
      final roomId = roomSessions.key;
      final sessions = roomSessions.value;

      for (final messsageSessions in sessions.entries) {
        final senderKey = messsageSessions.key;
        final messageIndex = ((messageSessionIndex[roomId] ?? {})[senderKey]) ?? 0;
        final sessionsSerialized = messsageSessions.value;

        final messageSessionNew = MessageSession(
          index: messageIndex,
          serialized: sessionsSerialized, // already pickled
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // new message session updates
        messageSessionsUpdated.update(
          roomId,
          (identitySessions) => identitySessions
            ..update(
              senderKey,
              (sessions) => sessions..insert(0, messageSessionNew),
              ifAbsent: () => [messageSessionNew],
            ),
          ifAbsent: () => {
            senderKey: [messageSessionNew],
          },
        );
      }
    }

    log.warn('[upgradeSessions_temp] COMPLETED, WIPING PREVIOUS KEY SESSIONS');

    return copyWith(
      messageSessionIndex: const {},
      inboundMessageSessions: const {},
      messageSessionsInbound: messageSessionsUpdated,
    );
  }

  Map<String, dynamic> toJson() => _$CryptoStoreToJson(this);
  factory CryptoStore.fromJson(Map<String, dynamic> json) => _$CryptoStoreFromJson(json);
}

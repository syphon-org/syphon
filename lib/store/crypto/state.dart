import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:olm/olm.dart';

import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/sessions/model.dart';

part 'state.g.dart';

@JsonSerializable()
class CryptoStore extends Equatable {
  // Active olm account (loaded from olmAccountKey)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Account? olmAccount;

  // Serialized olm account
  final String? olmAccountKey;

  final bool? deviceKeysExist;
  final bool deviceKeyVerified;
  final bool oneTimeKeysStable;

  // Map<identityKey, Map<SessionId, serializedSession>
  final Map<String, Map<String, String>> keySessions; // both olm inbound and outbound key sessions

  // Map<roomId, serializedSession> // megolm - messages
  final Map<String, String> outboundMessageSessions;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - messages per chat
  // NOTE: backed up to sqlite db storage, JsonKey ignore to not cache
  @JsonKey(includeFromJson: false, includeToJson: false)
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
    this.messageSessionsInbound = const {}, // Megolm Sessions
    this.outboundMessageSessions = const {}, // Megolm Sessions
    this.keySessions = const {}, // Olm sessions
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
    Map<String, String>? outboundMessageSessions,
    Map<String, Map<String, List<MessageSession>>>? messageSessionsInbound,
    Map<String, Map<String, String>>? keySessions,
    Map<String, DeviceKey>? deviceKeysOwned,
    Map<String, Map<String, DeviceKey>>? deviceKeys,
    Map<String, OneTimeKey>? oneTimeKeysClaimed,
    Map<String, int>? oneTimeKeysCounts,
  }) =>
      CryptoStore(
        olmAccount: olmAccount ?? this.olmAccount,
        olmAccountKey: olmAccountKey ?? this.olmAccountKey,
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

  Map<String, dynamic> toJson() => _$CryptoStoreToJson(this);
  factory CryptoStore.fromJson(Map<String, dynamic> json) => _$CryptoStoreFromJson(json);
}

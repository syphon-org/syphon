// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:olm/olm.dart';

// Project imports:
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/model.dart';

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

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - index per chat
  final Map<String, Map<String, int>> messageSessionIndex;

  // Map<roomId, serializedSession> // megolm - messages
  final Map<String, String> outboundMessageSessions;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - messages per chat
  final Map<String, Map<String, String>> inboundMessageSessions;

  // Map<identityKey, serializedSession> // olmv1 - key-sharing per identity
  final Map<String, String> inboundKeySessions;

  // Map<identityKey, serializedSession>  // olmv1 - key-sharing per identity
  final Map<String, String> outboundKeySessions;

  /// Map<UserId, Map<DeviceId, DeviceKey> deviceKeys
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  // Map<DeviceId, DeviceKey> deviceKeysOwned
  final Map<String, DeviceKey> deviceKeysOwned; // key is deviceId

  // Track last known uploaded key amounts
  final Map<String, int> oneTimeKeysCounts;

  final Map<String, OneTimeKey> oneTimeKeysClaimed;

  const CryptoStore({
    this.olmAccount,
    this.olmAccountKey,
    this.deviceKeysExist = false,
    this.deviceKeyVerified = false,
    this.inboundMessageSessions = const {}, // messages
    this.outboundMessageSessions = const {}, // messages //
    this.inboundKeySessions = const {}, // one-time device keys
    this.outboundKeySessions = const {}, // one-time device keys
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
        messageSessionIndex,
        inboundMessageSessions,
        outboundMessageSessions,
        inboundKeySessions,
        outboundKeySessions,
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
    Map<String, Map<String, int>>? messageSessionIndex,
    Map<String, Map<String, String>>? inboundMessageSessions,
    Map<String, String>? outboundMessageSessions,
    Map<String, String>? inboundKeySessions,
    Map<String, String>? outboundKeySessions,
    Map<String, DeviceKey>? deviceKeysOwned,
    Map<String, Map<String, DeviceKey>>? deviceKeys,
    Map<String, OneTimeKey>? oneTimeKeysClaimed,
    Map<String, int>? oneTimeKeysCounts,
  }) =>
      CryptoStore(
        olmAccount: olmAccount ?? this.olmAccount,
        olmAccountKey: olmAccountKey ?? this.olmAccountKey,
        inboundMessageSessions:
            inboundMessageSessions ?? this.inboundMessageSessions,
        outboundMessageSessions:
            outboundMessageSessions ?? this.outboundMessageSessions,
        messageSessionIndex: messageSessionIndex ?? this.messageSessionIndex,
        inboundKeySessions: inboundKeySessions ?? this.inboundKeySessions,
        outboundKeySessions: outboundKeySessions ?? this.outboundKeySessions,
        deviceKeys: deviceKeys ?? this.deviceKeys,
        deviceKeysOwned: deviceKeysOwned ?? this.deviceKeysOwned,
        oneTimeKeysClaimed: oneTimeKeysClaimed ?? this.oneTimeKeysClaimed,
        deviceKeysExist: deviceKeysExist ?? this.deviceKeysExist,
        deviceKeyVerified: deviceKeyVerified ?? this.deviceKeyVerified,
        oneTimeKeysCounts: oneTimeKeysCounts ?? this.oneTimeKeysCounts,
      );

  Map<String, dynamic> toJson() => _$CryptoStoreToJson(this);
  factory CryptoStore.fromJson(Map<String, dynamic> json) =>
      _$CryptoStoreFromJson(json);
}

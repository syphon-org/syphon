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
  final Account olmAccount;

  // the private key for one time keys is saved in olm?
  // Map<UserId, Map<DeviceId, OneTimeKey> deviceKeys
  @JsonKey(ignore: true)
  final Map oneTimeKeysOwned;

  // Serialized olm account
  final String olmAccountKey;

  // Map<roomId, index(int)> // megolm - message index
  final Map<String, int> messageSessionIndex;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - index per chat
  final Map<String, Map<String, int>> messageSessionIndexNEW;

  // Map<roomId, serializedSession> // megolm - messages
  final Map<String, String> outboundMessageSessions;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - messages per chat
  final Map<String, Map<String, String>> inboundMessageSessions;

  // Map<identityKey, serializedSession> // olmv1 - key-sharing per identity
  final Map<String, String> inboundKeySessions;

  // Map<identityKey, serializedSession>  // olmv1 - key-sharing per identity
  final Map<String, String> outboundKeySessions;

  // Map<UserId, Map<DeviceId, DeviceKey> deviceKeys
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  // Map<DeviceId, DeviceKey> deviceKeysOwned
  final Map<String, DeviceKey> deviceKeysOwned; // key is deviceId

  final bool deviceKeysExist;

  // Track last known uploaded key amounts
  final Map oneTimeKeysCounts;

  final Map<String, OneTimeKey> oneTimeKeysClaimed;

  const CryptoStore({
    this.olmAccount,
    this.olmAccountKey,
    this.inboundMessageSessions = const {}, // messages
    this.outboundMessageSessions = const {}, // messages //
    this.inboundKeySessions = const {}, // one-time device keys
    this.outboundKeySessions = const {}, // one-time device keys
    this.messageSessionIndex = const {},
    this.messageSessionIndexNEW = const {},
    this.deviceKeys = const {},
    this.deviceKeysOwned = const {},
    this.oneTimeKeysClaimed = const {},
    this.oneTimeKeysOwned = const {},
    this.deviceKeysExist = false,
    this.oneTimeKeysCounts,
  });

  @override
  List<Object> get props => [
        olmAccount,
        olmAccountKey,
        messageSessionIndexNEW,
        inboundMessageSessions,
        outboundMessageSessions,
        inboundKeySessions,
        outboundKeySessions,
        messageSessionIndex,
        deviceKeys,
        deviceKeysOwned,
        deviceKeysExist,
        oneTimeKeysOwned,
        oneTimeKeysClaimed,
        oneTimeKeysCounts
      ];

  CryptoStore copyWith({
    olmAccount,
    olmAccountKey,
    messageSessionIndexNEW,
    inboundMessageSessions,
    outboundMessageSessions,
    inboundKeySessions,
    outboundKeySessions,
    messageSessionIndex,
    deviceKeys,
    deviceKeysOwned,
    deviceKeysExist,
    oneTimeKeysOwned,
    oneTimeKeysClaimed,
    oneTimeKeysCounts,
  }) =>
      CryptoStore(
        olmAccount: olmAccount ?? this.olmAccount,
        olmAccountKey: olmAccountKey ?? this.olmAccountKey,
        inboundMessageSessions:
            inboundMessageSessions ?? this.inboundMessageSessions,
        outboundMessageSessions:
            outboundMessageSessions ?? this.outboundMessageSessions,
        messageSessionIndexNEW:
            messageSessionIndexNEW ?? this.messageSessionIndexNEW,
        messageSessionIndex: messageSessionIndex ?? this.messageSessionIndex,
        inboundKeySessions: inboundKeySessions ?? this.inboundKeySessions,
        outboundKeySessions: outboundKeySessions ?? this.outboundKeySessions,
        deviceKeys: deviceKeys ?? this.deviceKeys,
        deviceKeysOwned: deviceKeysOwned ?? this.deviceKeysOwned,
        oneTimeKeysOwned: oneTimeKeysOwned ?? this.oneTimeKeysOwned,
        oneTimeKeysClaimed: oneTimeKeysClaimed ?? this.oneTimeKeysClaimed,
        deviceKeysExist:
            deviceKeysExist != null ? deviceKeysExist : this.deviceKeysExist,
        oneTimeKeysCounts: oneTimeKeysCounts ?? this.oneTimeKeysCounts,
      );

  Map<String, dynamic> toJson() => _$CryptoStoreToJson(this);
  factory CryptoStore.fromJson(Map<String, dynamic> json) =>
      _$CryptoStoreFromJson(json);
}

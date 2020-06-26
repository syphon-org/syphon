import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:olm/olm.dart';

part 'state.g.dart';

// Next Hive Field Number: 12
@HiveType(typeId: CryptoStoreHiveId)
class CryptoStore extends Equatable {
  // Active olm account
  final Account olmAccount;

  // Serialized old account
  @HiveField(3)
  final String olmAccountKey;

  // DEPRECATED Map<roomId, serializedSession> // megolm - messages
  @HiveField(4)
  final Map<String, String> inboundMessageSessions;

  // Map<roomId, serializedSession> // megolm - messages
  @HiveField(5)
  final Map<String, String> outboundMessageSessions;

  // Map<roomId, Map<identityKey, serializedSession>  // megolm - messages
  @HiveField(11)
  final Map<String, Map<String, String>> messageSessionsInbound;

  // Map<roomId, index(int)> // megolm - messages
  @HiveField(10)
  final Map<String, int> messageSessionIndex;

  // Map<identityKey, serializedSession> // olmv1 - key-sharing
  @HiveField(8)
  final Map<String, String> inboundKeySessions;

  // Map<identityKey, serializedSession>  // olmv1 - key-sharing
  @HiveField(6)
  final Map<String, String> outboundKeySessions;

  // Map<UserId, Map<DeviceId, DeviceKey> deviceKeys
  @HiveField(0)
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  // Map<DeviceId, DeviceKey> deviceKeysOwned
  @HiveField(1)
  final Map<String, DeviceKey> deviceKeysOwned; // key is deviceId

  @HiveField(2)
  final bool deviceKeysExist;

  // Track last known uploaded key amounts
  @HiveField(7)
  final Map oneTimeKeysCounts;

  @HiveField(9)
  final Map<String, OneTimeKey> oneTimeKeysClaimed; // claimed

  // @HiveField(?) TODO: consider saving generated keys?
  // I think the private key for the
  // one time key is saved in olm?
  // Map<UserId, Map<DeviceId, OneTimeKey> deviceKeys
  final Map oneTimeKeysOwned;

  const CryptoStore({
    this.olmAccount,
    this.olmAccountKey,
    this.messageSessionsInbound = const {}, // messages
    this.inboundMessageSessions = const {}, // messages // DEPRECATED
    this.outboundMessageSessions = const {}, // messages //
    this.inboundKeySessions = const {}, // one-time device keys
    this.outboundKeySessions = const {}, // one-time device keys
    this.messageSessionIndex = const {},
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
    messageSessionsInbound,
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
  }) {
    return CryptoStore(
      olmAccount: olmAccount ?? this.olmAccount,
      olmAccountKey: olmAccountKey ?? this.olmAccountKey,
      messageSessionsInbound:
          messageSessionsInbound ?? this.messageSessionsInbound,
      outboundMessageSessions:
          outboundMessageSessions ?? this.outboundMessageSessions,

      // DEPCREATED
      inboundMessageSessions:
          inboundMessageSessions ?? this.inboundMessageSessions,

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
  }
}

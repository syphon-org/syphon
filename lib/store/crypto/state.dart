import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/store/crypto/keys/model.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:olm/olm.dart';

part 'state.g.dart';

// Next Hive Field Number: 10
@HiveType(typeId: CryptoStoreHiveId)
class CryptoStore extends Equatable {
  // Active olm account
  final Account olmAccount;

  // Serialized old account
  @HiveField(3)
  final String olmAccountKey;

  // Map<roomId, serializedSession>
  @HiveField(4)
  final Map<String, String> inboundMessageSessions; // megolm - messages

  // Map<roomId, serializedSession>
  @HiveField(5)
  final Map<String, String> outboundMessageSessions; // megolm - messages

  // Map<deviceId, serializedSession>
  @HiveField(8)
  final Map<String, String> inboundKeySessions; // olmv1 - key-sharing

  // Map<deviceId, serializedSession>
  @HiveField(6)
  final Map<String, String> outboundKeySessions; // olmv1 - key-sharing

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
    this.inboundMessageSessions = const {}, // messages
    this.outboundMessageSessions = const {}, // messages
    this.inboundKeySessions = const {}, // one-time device keys
    this.outboundKeySessions = const {}, // one-time device keys

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
    inboundMessageSessions,
    outboundMessageSessions,
    inboundKeySessions,
    outboundKeySessions,
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
      inboundMessageSessions:
          inboundMessageSessions ?? this.inboundMessageSessions,
      outboundMessageSessions:
          outboundMessageSessions ?? this.outboundMessageSessions,
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

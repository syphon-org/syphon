import 'package:Tether/global/libs/matrix/encryption.dart';
import 'package:Tether/store/crypto/model.dart';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:olm/olm.dart';

part 'state.g.dart';

@HiveType(typeId: CryptoStoreHiveId)
class CryptoStore extends Equatable {
  // Active olm account
  final Account olmAccount;
  // Serialized old account
  @HiveField(3)
  final String olmAccountKey;

  // Map<roomId, serializedSession>
  @HiveField(4)
  final Map<String, String> olmInboundSessions;

  // Map<roomId, serializedSession>
  @HiveField(5)
  final Map<String, String> olmOutboundSessions; // megolm

  // Map<roomId, serializedSession>
  @HiveField(4)
  final Map<String, String> olmInboundKeySessions; // olmv1

  // Map<roomId, serializedSession>
  @HiveField(6)
  final Map<String, String> olmOutboundKeySessions; // olmv1

  // Map<UserId, Map<DeviceId, DeviceKey> deviceKeys
  @HiveField(0)
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  // Map<DeviceId, DeviceKey> deviceKeysOwned
  @HiveField(1)
  final Map<String, DeviceKey> deviceKeysOwned; // key is deviceId

  @HiveField(2)
  final bool deviceKeysExist;

  final Map oneTimeKeys; //one time keys
  final Map oneTimeKeysOwned;
  final Map oneTimeKeysCounts; // only for owned ?

  const CryptoStore({
    this.olmAccount,
    this.olmAccountKey,
    this.olmInboundSessions = const {}, // messages
    this.olmOutboundSessions = const {}, // messages
    this.olmInboundKeySessions = const {}, // one-time device keys
    this.olmOutboundKeySessions = const {}, // one-time device keys

    this.deviceKeys = const {},
    this.deviceKeysOwned = const {},
    this.oneTimeKeys = const {},
    this.oneTimeKeysOwned = const {},
    this.deviceKeysExist = false,
    this.oneTimeKeysCounts,
  });

  @override
  List<Object> get props => [
        olmAccount,
        olmAccountKey,
        olmInboundSessions,
        olmOutboundSessions,
        olmInboundKeySessions,
        olmOutboundKeySessions,
        deviceKeys,
        deviceKeysOwned,
        deviceKeysExist,
        oneTimeKeys,
        oneTimeKeysOwned,
        oneTimeKeysCounts
      ];

  CryptoStore copyWith({
    olmAccount,
    olmAccountKey,
    olmInboundSessions,
    olmOutboundSessions,
    olmInboundKeySessions,
    olmOutboundKeySessions,
    deviceKeys,
    deviceKeysOwned,
    deviceKeysExist,
    oneTimeKeys,
    oneTimeKeysOwned,
    oneTimeKeysCounts,
  }) {
    return CryptoStore(
      olmAccount: olmAccount ?? this.olmAccount,
      olmAccountKey: olmAccountKey ?? this.olmAccountKey,
      olmInboundSessions: olmInboundSessions ?? this.olmInboundSessions,
      olmOutboundSessions: olmOutboundSessions ?? this.olmOutboundSessions,
      olmInboundKeySessions:
          olmInboundKeySessions ?? this.olmInboundKeySessions,
      olmOutboundKeySessions:
          olmOutboundKeySessions ?? this.olmOutboundKeySessions,
      deviceKeys: deviceKeys ?? this.deviceKeys,
      deviceKeysOwned: deviceKeysOwned ?? this.deviceKeysOwned,
      oneTimeKeys: oneTimeKeys ?? this.oneTimeKeys,
      oneTimeKeysOwned: oneTimeKeysOwned ?? this.oneTimeKeysOwned,
      deviceKeysExist:
          deviceKeysExist != null ? deviceKeysExist : this.deviceKeysExist,
      oneTimeKeysCounts: oneTimeKeysCounts ?? this.oneTimeKeysCounts,
    );
  }
}

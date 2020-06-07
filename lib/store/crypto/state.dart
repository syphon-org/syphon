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

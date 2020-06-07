import 'package:Tether/store/crypto/model.dart';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:olm/olm.dart';

part 'state.g.dart';

@HiveType(typeId: CryptoStoreHiveId)
class CryptoStore extends Equatable {
  // Map<UserId, Map<DeviceId, DeviceKey> deviceKeys
  @HiveField(0)
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  // Map<DeviceId, DeviceKey> deviceKeysOwned
  @HiveField(1)
  final Map<String, DeviceKey> deviceKeysOwned; // key is deviceId

  final Map messageKeys; //one time keys
  final Map messageKeysOwned;

  @HiveField(2)
  final bool deviceKeysExist;

  // Serialized old account
  @HiveField(3)
  final String olmAccountKey;

  // Active olm account
  final Account olmAccount;

  const CryptoStore({
    this.olmAccount,
    this.olmAccountKey,
    this.deviceKeys = const {},
    this.deviceKeysOwned = const {},
    this.messageKeys = const {},
    this.messageKeysOwned = const {},
    this.deviceKeysExist = false,
  });

  @override
  List<Object> get props => [
        olmAccount,
        olmAccountKey,
        deviceKeys,
        deviceKeysOwned,
        messageKeys,
        messageKeysOwned,
        deviceKeysExist,
      ];

  CryptoStore copyWith({
    olmAccount,
    olmAccountKey,
    deviceKeys,
    deviceKeysOwned,
    messageKeys,
    messageKeysOwned,
    deviceKeysExist,
  }) {
    return CryptoStore(
      olmAccount: olmAccount ?? this.olmAccount,
      olmAccountKey: olmAccountKey ?? this.olmAccountKey,
      deviceKeys: deviceKeys ?? this.deviceKeys,
      deviceKeysOwned: deviceKeysOwned ?? this.deviceKeysOwned,
      messageKeys: messageKeys ?? this.messageKeys,
      messageKeysOwned: messageKeysOwned ?? this.messageKeysOwned,
      deviceKeysExist:
          deviceKeysExist != null ? deviceKeysExist : this.deviceKeysExist,
    );
  }
}

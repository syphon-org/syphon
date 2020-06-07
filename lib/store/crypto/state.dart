import 'package:Tether/store/crypto/model.dart';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';

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

  const CryptoStore({
    this.deviceKeys = const {},
    this.deviceKeysOwned = const {},
    this.messageKeys = const {},
    this.messageKeysOwned = const {},
    this.deviceKeysExist = false,
  });

  @override
  List<Object> get props => [
        deviceKeys,
        deviceKeysOwned,
        messageKeys,
        messageKeysOwned,
        deviceKeysExist,
      ];

  CryptoStore copyWith({
    deviceKeys,
    deviceKeysOwned,
    messageKeys,
    messageKeysOwned,
    deviceKeysExist,
  }) {
    return CryptoStore(
      deviceKeys: deviceKeys ?? this.deviceKeys,
      deviceKeysOwned: deviceKeysOwned ?? this.deviceKeysOwned,
      messageKeys: messageKeys ?? this.messageKeys,
      messageKeysOwned: messageKeysOwned ?? this.messageKeysOwned,
      deviceKeysExist:
          deviceKeysExist != null ? deviceKeysExist : this.deviceKeysExist,
    );
  }
}

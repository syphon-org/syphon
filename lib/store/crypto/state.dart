import 'package:Tether/store/crypto/model.dart';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';

part 'state.g.dart';

@HiveType(typeId: CryptoStoreHiveId)
class CryptoStore extends Equatable {
  @HiveField(1)
  final Map<String, DeviceKey> currentUserKeys;

  @HiveField(0)
  final Map<String, Map<String, DeviceKey>> deviceKeys;

  const CryptoStore({
    this.deviceKeys,
    this.currentUserKeys,
  });

  @override
  List<Object> get props => [
        deviceKeys,
        currentUserKeys,
      ];

  CryptoStore copyWith({
    deviceKeys,
    currentUserKeys,
  }) {
    return CryptoStore(
      deviceKeys: deviceKeys ?? this.deviceKeys,
      currentUserKeys: currentUserKeys ?? this.currentUserKeys,
    );
  }
}

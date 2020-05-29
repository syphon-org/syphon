import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';

part 'state.g.dart';

@HiveType(typeId: KeyStoreHiveId)
class KeyStore extends Equatable {
  @HiveField(0)
  final Map<String, String> deviceKeys;

  const KeyStore({
    this.deviceKeys,
  });

  @override
  List<Object> get props => [
        deviceKeys,
      ];

  KeyStore copyWith({
    deviceKeys,
  }) {
    return KeyStore(
      deviceKeys: deviceKeys ?? this.deviceKeys,
    );
  }
}

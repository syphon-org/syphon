import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

/**
 * 
 * OneTimeKey Data Model
 * 
 * 
 * https://matrix.org/docs/spec/client_server/latest#id468
 * {
  "failures": {},
    "one_time_keys": {
      "@alice:example.com": {
        "JLAFKJWSCS": {
          "signed_curve25519:AAAAHg": {
            "key": "zKbLg+NrIjpnagy+pIY6uPL4ZwEG2v+8F9lmgsnlZzs",
            "signatures": {
              "@alice:example.com": {
                "ed25519:JLAFKJWSCS": "FLWxXqGbwrb8SM3Y795eB6OA8bwBcoMZFXBqnTn58AYWZSqiD45tlBVcDa2L7RwdKXebW/VzDlnfVJ+9jok1Bw"
              }
            }
          }
        }
      }
    }
  }
 */
@HiveType(typeId: OneTimeKeyHiveId)
class OneTimeKey extends Equatable {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String deviceId;
  @HiveField(3)
  final Map<String, Map<String, String>> keys;

  const OneTimeKey({
    this.userId,
    this.deviceId,
    this.keys,
  });

  @override
  List<Object> get props => [
        userId,
        deviceId,
        keys,
      ];

  factory OneTimeKey.fromJson(dynamic json) {
    try {
      return OneTimeKey(
        userId: json['user_id'],
        deviceId: json['device_id'],
        keys: Map.from(json['keys']),
      );
    } catch (error) {
      print('[DeviceKey.fromJson] error $error');
      return OneTimeKey();
    }
  }
}

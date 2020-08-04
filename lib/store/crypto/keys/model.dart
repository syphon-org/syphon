// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';

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

  // Map<identityKey, key>
  @HiveField(2)
  final Map<String, String> keys;

  // Map<identityKey, signature>
  @HiveField(3)
  final Map<String, Map<String, String>> signatures;

  const OneTimeKey({
    this.userId,
    this.deviceId,
    this.keys,
    this.signatures,
  });

  @override
  List<Object> get props => [
        userId,
        deviceId,
        keys,
        signatures,
      ];
}

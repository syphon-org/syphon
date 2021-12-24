import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/storage/database.dart';

part 'model.g.dart';

@JsonSerializable()
class Receipt implements drift.Insertable<Receipt> {
  final String eventId;
  final int? latestRead;

  // required to be dynamic to convert to / from json
  final Map<String, dynamic>? userReadsMapped; // UserId -> timestamp (int)

  const Receipt({
    this.eventId = '',
    this.latestRead = 0,
    this.userReadsMapped = const {},
  });

  Map<String, int> get userReads {
    try {
      return Map<String, int>.from(userReadsMapped ?? {});
    } catch (error) {
      return {};
    }
  }

  factory Receipt.fromMatrix(String eventId, Map<String, dynamic> receipt) {
    final usersRead = <String, int>{};
    final Map<String, dynamic> userTimestamps = receipt['m.read'];

    var latestTimestamp = 0;

    // { @someone:xxx.com: { ts: 15878525620000 }, @anotherone:somewhere.net: { ts: 1587852560000 } } }
    userTimestamps.forEach(
      (userId, value) {
        final userTimestamp = value['ts'] as int;
        usersRead[userId] = userTimestamp;
        latestTimestamp = userTimestamp > latestTimestamp ? userTimestamp : latestTimestamp;
      },
    );

    return Receipt(
      eventId: eventId,
      userReadsMapped: usersRead,
      latestRead: latestTimestamp,
    );
  }

  Receipt copyWith({
    eventId,
    userReads,
    latestRead,
  }) =>
      Receipt(
        eventId: eventId ?? this.eventId,
        latestRead: latestRead ?? this.latestRead,
        userReadsMapped: userReads ?? userReadsMapped,
      );

  Map<String, dynamic> toJson() => _$ReceiptToJson(this);
  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    return ReceiptsCompanion(
      eventId: drift.Value(eventId),
      latestRead: drift.Value(latestRead),
      userReads: drift.Value(json.decode(json.encode(userReads))),
    ).toColumns(nullToAbsent);
  }
}

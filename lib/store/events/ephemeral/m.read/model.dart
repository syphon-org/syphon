import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class ReadReceipt {
  final int? latestRead;
  final Map<String, int>? userReads; // UserId -> timestamp

  const ReadReceipt({
    this.latestRead = 0,
    this.userReads,
  });

  factory ReadReceipt.fromReceipt(Map<String, dynamic> receipt) {
    final usersRead = <String, int>{};
    var latestTimestamp = 0;
    final Map<String, dynamic> userTimestamps = receipt['m.read'];

    // { @someone:xxx.com: { ts: 15878525620000 }, @anotherone:somewhere.net: { ts: 1587852560000 } } }
    userTimestamps.forEach(
      (userId, value) {
        final userTimestamp = (value['ts'] as int);
        usersRead[userId] = userTimestamp;
        latestTimestamp =
            userTimestamp > latestTimestamp ? userTimestamp : latestTimestamp;
      },
    );

    return ReadReceipt(
      userReads: usersRead,
      latestRead: latestTimestamp,
    );
  }

  ReadReceipt copyWith({
    usersRead,
    latestRead,
  }) =>
      ReadReceipt(
        userReads: usersRead ?? userReads,
        latestRead: latestRead ?? this.latestRead,
      );

  Map<String, dynamic> toJson() => _$ReadReceiptToJson(this);
  factory ReadReceipt.fromJson(Map<String, dynamic> json) =>
      _$ReadReceiptFromJson(json);
}

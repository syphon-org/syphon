// Package imports:
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class ReadStatus {
  final int latestRead;
  final Map<String, int> userReads; // UserId -> timestamp

  const ReadStatus({
    this.latestRead = 0,
    this.userReads,
  });

  factory ReadStatus.fromReceipt(Map<String, dynamic> receipt) {
    var usersRead = Map<String, int>();
    var latestTimestamp = 0;
    final Map<String, dynamic> userTimestamps = receipt['m.read'];

    // { @someone:xxx.com: { ts: 15878525620000 }, @anotherone:somewhere.net: { ts: 1587852560000 } } }
    userTimestamps.forEach(
      (userId, value) {
        var userTimestamp = (value['ts'] as int);
        usersRead[userId] = userTimestamp;
        latestTimestamp =
            userTimestamp > latestTimestamp ? userTimestamp : latestTimestamp;
      },
    );

    return ReadStatus(
      userReads: usersRead,
      latestRead: latestTimestamp,
    );
  }

  ReadStatus copyWith({
    usersRead,
    latestRead,
  }) =>
      ReadStatus(
        userReads: usersRead ?? this.userReads,
        latestRead: latestRead ?? this.latestRead,
      );

  Map<String, dynamic> toJson() => _$ReadStatusToJson(this);
  factory ReadStatus.fromJson(Map<String, dynamic> json) =>
      _$ReadStatusFromJson(json);
}

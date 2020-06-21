import 'package:hive/hive.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';

part 'model.g.dart';

@HiveType(typeId: ReadStatusHiveId)
class ReadStatus {
  @HiveField(0)
  final int latestRead;

  // UserId -> timestamp
  @HiveField(1)
  final Map<String, int> userReads;

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
  }) {
    return ReadStatus(
      userReads: usersRead ?? this.userReads,
      latestRead: latestRead ?? this.latestRead,
    );
  }
}

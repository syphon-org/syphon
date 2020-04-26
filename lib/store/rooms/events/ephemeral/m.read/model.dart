import 'package:Tether/store/rooms/events/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class ReadStatus {
  final int latestRead;

  // UserId -> timestamp
  final Map<String, int> userReads;

  const ReadStatus({
    this.userReads,
    this.latestRead = 0,
  });

  factory ReadStatus.fromReceipt(Map<String, dynamic> receipt) {
    var usersRead = Map<String, int>();
    var latestTimestamp = 0;
    final Map<String, dynamic> userTimestamps = receipt['m.read'];

    // { @someone:xxx.com: { ts: 15878525620000 }, @anotherone:somewhere.net: { ts: 1587852560000 } } }
    userTimestamps.forEach((userId, value) {
      var userTimestamp = (value['ts'] as int);
      usersRead[userId] = userTimestamp;
      latestTimestamp =
          userTimestamp > latestTimestamp ? userTimestamp : latestTimestamp;
    });

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

@jsonSerializable
class UserReadStatus {}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/parsers.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/redactions/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/model.dart';

part 'parsers.freezed.dart';

@freezed
abstract class SyncPayload with _$SyncPayload {
  factory SyncPayload({
    Room room,
    List<Event> state,
    List<Reaction> reactions,
    List<Redaction> redactions,
    List<Message> messages,
    Map<String, ReadReceipt> readReceipts,
    Map<String, User> users,
  }) = _SyncPayload;
}

Room parseRoom(Map params) {
  Map json = params['json'];
  Room room = params['room'];
  User currentUser = params['currentUser'];
  String lastSince = params['lastSince'];

  // TODO: eventually remove the need for this with modular parsers
  return room.fromSync(
    json: json,
    currentUser: currentUser,
    lastSince: lastSince,
  );
}

Map<String, dynamic> parseRoomSync(Map params) {
  Map json = params['json'];
  Room room = params['room'];
  User currentUser = params['currentUser'];
  String lastSince = params['lastSince'];

  Map events = parseEvents(json);

  return {
    'room': room,
    ...events,
  };
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:io';

import 'package:syphon/store/events/parsers.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backfilling', () {
    test('Room backfill should be true when payload is "limited"', () async {
      final room = Room();

      final file = new File('test/store/rooms/room/payload_limited.json');
      final json = jsonDecode(await file.readAsString());

      final roomId = '!726s6s6q:example.com';
      final roomData = json['rooms']['join']['${roomId}'];
      final roomUpdated = room.fromTimelineData(json: roomData);

      expect(roomUpdated.backfilling, true);
    });

    test(
        'Room backfill should remain true even after receiving a false "limited" payload ',
        () async {
      var file = new File('test/store/rooms/room/payload_limited.json');
      var json = jsonDecode(await file.readAsString());

      var roomId = '!726s6s6q:example.com';
      var roomData = json['rooms']['join']['${roomId}'];
      var room = Room(id: roomId);

      var roomUpdated = room.fromTimelineData(json: roomData);

      expect(roomUpdated.limited, false);
      expect(roomUpdated.backfilling, true);
      expect(room.id, roomId);

      file = new File('test/store/rooms/room/payload_full.json');
      json = jsonDecode(await file.readAsString());

      roomId = '!726s6s6q:example.com';
      roomData = json['rooms']['join']['${roomId}'];
      roomUpdated = roomUpdated.fromTimelineData(json: roomData);

      expect(roomUpdated.limited, false);
      expect(roomUpdated.backfilling, true);
    });
  });

  test(
      'Room backfill should be false when payload returns known events or no prev_batch',
      () async {
    var file = new File('test/store/rooms/room/payload_limited.json');
    var json = jsonDecode(await file.readAsString());

    var roomId = '!726s6s6q:example.com';
    var roomData = json['rooms']['join']['${roomId}'];
    var room = Room(id: roomId);

    var roomUpdated = room.fromTimelineData(json: roomData);

    expect(roomUpdated.backfilling, true);

    file = new File('test/store/rooms/room/payload_full.json');
    json = jsonDecode(await file.readAsString());

    final events = parseEvents(json);

    expect(roomUpdated.backfilling, false);

    // roomUpdated = roomUpdated.fromMessageEvents(json: roomData);
  });
}

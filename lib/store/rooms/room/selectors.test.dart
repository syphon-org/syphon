import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:test/test.dart';

void main() {
  group('[Room Selectors] ', () {
    test('formatPreview - topic null', () {
      final previewRoom = Room(id: '1234', topic: null);

      final previewText = formatPreview(room: previewRoom);

      expect('No messages', equals(previewText));
    });
    test('formatPreview - topic empty', () {
      final previewRoom = Room(id: '1234', topic: '');

      final previewText = formatPreview(room: previewRoom);

      expect('No messages', equals(previewText));
    });
    test('formatPreview - message null', () {
      final previewRoom = Room(id: '1234', topic: '');

      final previewText = formatPreview(room: previewRoom, message: null);

      expect('No messages', equals(previewText));
    });
  });
}

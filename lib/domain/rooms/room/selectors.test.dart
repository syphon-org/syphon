import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/room/selectors.dart';
import 'package:test/test.dart';

void main() {
  group('[Room Selectors] ', () {
    test('formatPreview - topic null', () {
      const previewRoom = Room(id: '1234', topic: null);

      final previewText = formatPreview(room: previewRoom);

      expect('No messages', equals(previewText));
    });
    test('formatPreview - topic empty', () {
      const previewRoom = Room(id: '1234', topic: '');

      final previewText = formatPreview(room: previewRoom);

      expect('No messages', equals(previewText));
    });
    test('formatPreview - message null', () {
      const previewRoom = Room(id: '1234', topic: '');

      final previewText = formatPreview(room: previewRoom, message: null);

      expect('No messages', equals(previewText));
    });
  });
}

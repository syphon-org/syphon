import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:test/test.dart';

void main() {
  group('Event Selectors]', () {
    test('latestMessage - one message works', () {
      final messageLatest = Message(timestamp: 2);
      final result = latestMessage([messageLatest]);

      expect(result, equals(messageLatest));
    });

    test('latestMessage - largest timestamp of 2 wins', () {
      final messageLatest = Message(timestamp: 2);
      final result = latestMessage([messageLatest, Message()]);

      expect(result, equals(messageLatest));
    });

    test('latestMessage - empty list', () {
      final result = latestMessage([]);

      expect(result, equals(null));
    });
  });
}

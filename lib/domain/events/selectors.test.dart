import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/selectors.dart';
import 'package:test/test.dart';

void main() {
  group('Event Selectors]', () {
    test('latestMessage - one message works', () {
      const messageLatest = Message(timestamp: 2);
      final result = latestMessage([messageLatest]);

      expect(result, equals(messageLatest));
    });

    test('latestMessage - largest timestamp of 2 wins', () {
      const messageLatest = Message(timestamp: 2);
      final result = latestMessage([messageLatest, const Message()]);

      expect(result, equals(messageLatest));
    });

    test('latestMessage - empty list', () {
      final result = latestMessage([]);

      expect(result, equals(null));
    });
  });
}

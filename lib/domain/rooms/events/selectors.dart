import 'package:Tether/domain/rooms/events/model.dart';

List<Message> latestMessages(List<Message> messages) {
  final sortedList = messages;

  // sort descending
  messages.sort((a, b) {
    if (a.pending && !b.pending) {
      return -1;
    }

    if (a.timestamp > b.timestamp) {
      return -1;
    }
    if (a.timestamp < b.timestamp) {
      return 1;
    }

    return 0;
  });

  return sortedList;
}

List<Message> wrapOutboxMessages(
    {List<Message> messages, List<Message> outbox}) {
  return [outbox, messages].expand((x) => x).toList();
}

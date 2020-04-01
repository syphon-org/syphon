import 'package:Tether/domain/rooms/events/model.dart';

List<Message> sortedMessages(List<Message> messages) {
  final sortedList = List<Message>.from(messages);

  // sort descending
  sortedList.sort((a, b) {
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

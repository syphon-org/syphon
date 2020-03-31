import 'package:Tether/domain/rooms/events/model.dart';

List<Event> sortedMessages(List<Event> messages) {
  final sortedList = List<Event>.from(messages);

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

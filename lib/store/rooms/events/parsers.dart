import 'package:sembast/sembast.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/user/model.dart';

Future<List<Event>> parseStateEvents(
  Map<String, dynamic> json, {
  Database database,
}) {
  List<Event> stateEvents = [];

  if (json['state'] != null) {
    final List<dynamic> stateEventsRaw = json['state']['events'];

    stateEvents =
        stateEventsRaw.map((event) => Event.fromMatrix(event)).toList();
  }

  if (json['invite_state'] != null) {
    final List<dynamic> stateEventsRaw = json['invite_state']['events'];

    stateEvents =
        stateEventsRaw.map((event) => Event.fromMatrix(event)).toList();
  }

  if (json['timeline'] != null) {
    final List<dynamic> timelineEventsRaw = json['timeline']['events'];

    for (dynamic event in timelineEventsRaw) {
      if (!(event['type'] == EventTypes.message ||
          event['type'] == EventTypes.encrypted)) {
        stateEvents.add(Event.fromMatrix(event));
      }
    }
  }

  return Future.value();
}

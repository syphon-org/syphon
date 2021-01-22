

import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/index.dart';

Map<String, Message> filterRedacted(
  Map<String, Message> messages, {
  AppState state,
}) {
  final redactions = state.eventStore.redactions; 

  final List<String> reactionKeys =
      reactions.keys.where((k) => messages.containsKey(k)).toList();

  // the bet here is never will be many redactions
  redactions.forEach((key, value) {
    if(messages.containsKey(key) || ){}
  });
}
 
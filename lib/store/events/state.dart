// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/messages/model.dart';

import 'model.dart';

part 'state.g.dart';

@JsonSerializable()
class EventStore extends Equatable {
  final Map<String, List<Event>> events; // indexed by roomId
  final Map<String, List<Event>> receipts;
  final Map<String, List<Event>> reactions;
  final Map<String, List<Message>> messages; // indexed by roomId

  const EventStore({
    this.events = const {},
    this.messages = const {},
    this.reactions = const {},
    this.receipts = const {},
  });

  @override
  List<Object> get props => [
        events,
        messages,
        reactions,
        receipts,
      ];

  EventStore copyWith({
    events,
    messages,
    reactions,
    receipts,
  }) =>
      EventStore(
        events: events ?? this.events,
        messages: messages ?? this.messages,
        reactions: reactions ?? this.reactions,
        receipts: receipts ?? this.receipts,
      );

  Map<String, dynamic> toJson() => _$EventStoreToJson(this);
  factory EventStore.fromJson(Map<String, dynamic> json) =>
      _$EventStoreFromJson(json);
}

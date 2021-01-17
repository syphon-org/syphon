// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/messages/model.dart';

import 'model.dart';

part 'state.g.dart';

@JsonSerializable()
class EventStore extends Equatable {
  final Map<String, List<Event>> events; // indexed by roomId
  final Map<String, List<Message>> messages; // indexed by roomId
  final Map<String, List<Event>> receipts;

  const EventStore({
    this.events = const {},
    this.messages = const {},
    this.receipts = const {},
  });

  @override
  List<Object> get props => [
        events,
        messages,
        receipts,
      ];

  EventStore copyWith({
    events,
    messages,
  }) =>
      EventStore(
        events: events ?? this.events,
        messages: messages ?? this.messages,
        receipts: receipts ?? this.receipts,
      );

  Map<String, dynamic> toJson() => _$EventStoreToJson(this);
  factory EventStore.fromJson(Map<String, dynamic> json) =>
      _$EventStoreFromJson(json);
}

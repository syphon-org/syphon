// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

import 'model.dart';

part 'state.g.dart';

@JsonSerializable()
class EventStore extends Equatable {
  final Map<String, List<Event>> events; // roomId indexed
  final Map<String, Redaction> redactions; // eventId indexed
  final Map<String, List<Message>> messages; // roomId indexed
  final Map<String, List<Reaction>> reactions; // eventId indexed
  final Map<String, Map<String, ReadReceipt>> receipts; // eventId indexed
  final Map<String, Map<String, Message>> outbox; // roomId and tempId subindex

  const EventStore({
    this.events = const {},
    this.messages = const {},
    this.reactions = const {},
    this.receipts = const {},
    this.redactions = const {},
    this.outbox = const {},
  });

  @override
  List<Object> get props => [
        events,
        messages,
        reactions,
        receipts,
        redactions,
        outbox,
      ];

  EventStore copyWith({
    Map<String, List<Event>>? events,
    Map<String, List<Message>>? messages,
    Map<String, Redaction>? redactions,
    Map<String, List<Reaction>>? reactions,
    Map<String, Map<String, ReadReceipt>>? receipts,
    Map<String, Map<String, Message>>? outbox,
  }) =>
      EventStore(
        events: events ?? this.events,
        messages: messages ?? this.messages,
        redactions: redactions ?? this.redactions,
        reactions: reactions ?? this.reactions,
        receipts: receipts ?? this.receipts,
        outbox: outbox ?? this.outbox,
      );

  Map<String, dynamic> toJson() => _$EventStoreToJson(this);
  factory EventStore.fromJson(Map<String, dynamic> json) =>
      _$EventStoreFromJson(json);
}

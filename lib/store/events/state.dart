import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

import 'model.dart';

part 'state.g.dart';

///
/// Event Store
///
/// Eventually, convert all to be indexed like the following
///
/// Map<RoomId, Map<EventId, Event>>
///
@JsonSerializable()
class EventStore extends Equatable {
  final Map<String, List<Event>> events; // roomId indexed - state events
  final Map<String, Redaction> redactions; // eventId indexed
  final Map<String, List<Message>> messages; // roomId indexed
  final Map<String, List<Reaction>> reactions; // eventId indexed
  final Map<String, Map<String, Receipt>> receipts; // eventId, userId indexed
  final Map<String, Map<String, Message>> outbox; // roomId, tempId subindex
  final Map<String, List<Message>> messagesDecrypted; // messages decrypted - in memory only

  const EventStore({
    this.events = const {},
    this.messages = const {},
    this.messagesDecrypted = const {},
    this.reactions = const {},
    this.receipts = const {},
    this.redactions = const {},
    this.outbox = const {},
  });

  @override
  List<Object> get props => [
        events,
        messages,
        messagesDecrypted,
        reactions,
        receipts,
        redactions,
        outbox,
      ];

  EventStore copyWith({
    Map<String, List<Event>>? events,
    Map<String, List<Message>>? messages,
    Map<String, List<Message>>? messagesDecrypted,
    Map<String, Redaction>? redactions,
    Map<String, List<Reaction>>? reactions,
    Map<String, Map<String, Receipt>>? receipts,
    Map<String, Map<String, Message>>? outbox,
  }) =>
      EventStore(
        events: events ?? this.events,
        messages: messages ?? this.messages,
        messagesDecrypted: messagesDecrypted ?? this.messagesDecrypted,
        redactions: redactions ?? this.redactions,
        reactions: reactions ?? this.reactions,
        receipts: receipts ?? this.receipts,
        outbox: outbox ?? this.outbox,
      );

  Map<String, dynamic> toJson() => _$EventStoreToJson(this);
  factory EventStore.fromJson(Map<String, dynamic> json) => _$EventStoreFromJson(json);
}

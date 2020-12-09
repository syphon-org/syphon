// Dart imports:
import 'dart:async';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'state.g.dart';

@JsonSerializable()
class EventStore extends Equatable {
  final Map<String, List<Event>> states; // indexed by roomId
  final Map<String, List<Message>> messages; // indexed by roomId
  final Map<String, List<Event>> receipts;

  const EventStore({
    this.states = const {},
    this.messages = const {},
    this.receipts = const {},
  });

  @override
  List<Object> get props => [
        states,
        messages,
        receipts,
      ];

  EventStore copyWith({
    states,
    messages,
  }) =>
      EventStore(
        states: states ?? this.states,
        messages: messages ?? this.messages,
        receipts: receipts ?? this.receipts,
      );

  Map<String, dynamic> toJson() => _$EventStoreToJson(this);
  factory EventStore.fromJson(Map<String, dynamic> json) =>
      _$EventStoreFromJson(json);
}

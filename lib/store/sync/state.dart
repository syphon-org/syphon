import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'state.g.dart';

@JsonSerializable()
class SyncStore extends Equatable {
  final bool synced;
  final bool offline;
  final bool backgrounded;

  final int? lastUpdate; // Last timestamp for actual new info
  final int? lastAttempt; // last attempt to sync
  final String? lastSince; // Since we last checked for new info

  @JsonKey(ignore: true)
  final int backoff;

  @JsonKey(ignore: true)
  final bool syncing;

  @JsonKey(ignore: true)
  final bool unauthed;

  @JsonKey(ignore: true)
  final Timer? syncObserver;

  const SyncStore({
    this.synced = false,
    this.syncing = false,
    this.unauthed = false,
    this.offline = false,
    this.backgrounded = false,
    this.lastUpdate = 0,
    this.lastAttempt = 0,
    this.backoff = 0,
    this.lastSince,
    this.syncObserver,
  });

  @override
  List<Object?> get props => [
        synced,
        syncing,
        offline,
        backoff,
        unauthed,
        backgrounded,
        lastUpdate,
        lastAttempt,
        lastSince,
        syncObserver,
      ];

  SyncStore copyWith({
    int? backoff,
    bool? synced,
    bool? syncing,
    bool? offline,
    bool? unauthed,
    bool? backgrounded,
    int? lastUpdate,
    int? lastAttempt,
    Timer? syncObserver,
    String? lastSince,
  }) =>
      SyncStore(
        synced: synced ?? this.synced,
        syncing: syncing ?? this.syncing,
        offline: offline ?? this.offline,
        unauthed: unauthed ?? this.unauthed,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        lastAttempt: lastAttempt ?? this.lastAttempt,
        lastSince: lastSince ?? this.lastSince,
        syncObserver: syncObserver ?? this.syncObserver,
        backgrounded: backgrounded ?? this.backgrounded,
        backoff: backoff ?? this.backoff,
      );

  Map<String, dynamic> toJson() => _$SyncStoreToJson(this);

  factory SyncStore.fromJson(Map<String, dynamic> json) =>
      _$SyncStoreFromJson(json);
}

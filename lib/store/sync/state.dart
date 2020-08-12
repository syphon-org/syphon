// Dart imports:
import 'dart:async';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';

part 'state.g.dart';

@HiveType(typeId: SyncStoreHiveId)
class SyncStore extends Equatable {
  @HiveField(0)
  final bool synced;

  @HiveField(3)
  final int lastUpdate; // Last timestamp for actual new info

  @HiveField(4)
  final String lastSince; // Since we last checked for new info

  static const default_interval = 1;

  @HiveField(5)
  final int interval = default_interval;

  final int backoff;
  final bool syncing;
  final bool offline;
  final bool unauthed;
  final Timer syncObserver;

  final int lastAttempt; // last attempt to sync

  const SyncStore({
    this.synced = false,
    this.syncing = false,
    this.unauthed = false,
    this.offline = false,
    this.lastUpdate = 0,
    this.lastAttempt = 0,
    this.backoff = 0,
    this.lastSince,
    this.syncObserver,
  });

  @override
  List<Object> get props => [
        synced,
        syncing,
        offline,
        backoff,
        unauthed,
        lastUpdate,
        lastAttempt,
        lastSince,
        syncObserver,
      ];

  SyncStore copyWith({
    synced,
    syncing,
    offline,
    backoff,
    unauthed,
    lastUpdate,
    lastAttempt,
    syncObserver,
    lastSince,
  }) {
    return SyncStore(
      synced: synced ?? this.synced,
      syncing: syncing ?? this.syncing,
      offline: offline ?? this.offline,
      unauthed: unauthed ?? this.unauthed,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastSince: lastSince ?? this.lastSince,
      syncObserver: syncObserver ?? this.syncObserver,
      backoff: backoff ?? this.backoff,
    );
  }
}

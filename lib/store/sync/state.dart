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

  @HiveField(6)
  final int lastAttempt; // last attempt to sync

  @HiveField(7)
  final bool backgrounded;

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
  List<Object> get props => [
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
    int backoff,
    bool synced,
    bool syncing,
    bool offline,
    bool unauthed,
    bool backgrounded,
    int lastUpdate,
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
      lastAttempt: lastAttempt ??
          this.lastAttempt ??
          0, // TODO: remove after version 0.1.4
      lastSince: lastSince ?? this.lastSince,
      syncObserver: syncObserver ?? this.syncObserver,
      backgrounded: backgrounded ??
          this.backgrounded ??
          false, // TODO: remove after version 0.1.4
      backoff: backoff ?? this.backoff,
    );
  }
}

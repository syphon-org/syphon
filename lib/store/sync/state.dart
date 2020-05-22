import 'dart:async';

import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';

part 'state.g.dart';

@HiveType(typeId: SyncStoreHiveId)
class SyncStore extends Equatable {
  @HiveField(0)
  final bool synced;

  @HiveField(3)
  final int lastUpdate; // Last timestamp for actual new info

  @HiveField(4)
  final String lastSince; // Since we last checked for new info

  @HiveField(5)
  final int interval = default_interval;

  final int backoff;
  final bool loading;
  final bool syncing;
  final Timer syncObserver;

  static const default_interval = 5;

  const SyncStore({
    this.synced = false,
    this.syncing = false,
    this.loading = false,
    this.lastUpdate = 0,
    this.backoff,
    this.lastSince,
    this.syncObserver,
  });

  @override
  List<Object> get props => [
        loading,
        syncing,
        synced,
        lastUpdate,
        lastSince,
        syncObserver,
      ];

  SyncStore copyWith({
    synced,
    loading,
    syncing,
    lastUpdate,
    syncObserver,
    lastSince,
    backoff,
  }) {
    return SyncStore(
      synced: synced ?? this.synced,
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastSince: lastSince ?? this.lastSince,
      syncObserver: syncObserver ?? this.syncObserver,
      backoff: backoff ?? this.backoff,
    );
  }
}

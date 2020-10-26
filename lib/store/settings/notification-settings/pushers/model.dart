// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';

part 'model.g.dart';

@HiveType(typeId: PusherHiveId)
@JsonSerializable()
class Pusher extends Equatable {
  @HiveField(0)
  final String key;
  @HiveField(1)
  final String kind;
  @HiveField(2)
  final String appId;
  @HiveField(3)
  final String appDisplayName;

  const Pusher({
    this.key,
    this.kind,
    this.appId,
    this.appDisplayName,
  });

  @override
  List<Object> get props => [
        key,
        kind,
        appId,
        appDisplayName,
      ];

  Pusher copyWith({
    key,
    kind,
    appId,
    appDisplayName,
  }) =>
      Pusher(
        key: key ?? this.key,
        kind: kind ?? this.kind,
        appId: appId ?? this.appId,
        appDisplayName: appDisplayName ?? this.appDisplayName,
      );

  factory Pusher.fromMatrix(dynamic json) {
    try {
      return Pusher(
        key: json['pushkey'],
        kind: json['kind'],
        appId: json['app_id'],
        appDisplayName: json['app_display_name'],
      );
    } catch (error) {
      return Pusher(
        key: json['pushkey'],
      );
    }
  }

  Map<String, dynamic> toJson() => _$PusherToJson(this);

  factory Pusher.fromJson(Map<String, dynamic> json) => _$PusherFromJson(json);
}

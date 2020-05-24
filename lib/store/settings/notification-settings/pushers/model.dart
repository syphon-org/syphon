import 'package:equatable/equatable.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: PusherHiveId)
class Pusher extends Equatable {
  @HiveField(0)
  final String key;
  @HiveField(1)
  final String kind;
  @HiveField(2)
  final String appId;
  @HiveField(3)
  final String appDisplayName;

  const Pusher({this.key, this.kind, this.appId, this.appDisplayName});

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
  }) {
    return Pusher(
      key: key ?? this.key,
      kind: kind ?? this.kind,
      appId: appId ?? this.appId,
      appDisplayName: appDisplayName ?? this.appDisplayName,
    );
  }

  factory Pusher.fromJson(dynamic json) {
    try {
      return Pusher(
        key: json['pushkey'],
        kind: json['kind'],
        appId: json['app_id'],
        appDisplayName: json['app_display_name'],
      );
    } catch (error) {
      print('[Device.fromJson] error $error');
      return Pusher(
        key: json['pushkey'],
      );
    }
  }
}

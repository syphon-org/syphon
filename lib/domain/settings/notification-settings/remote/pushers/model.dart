import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Pusher extends Equatable {
  final String? key;
  final String? kind;
  final String? appId;
  final String? appDisplayName;

  const Pusher({
    this.key,
    this.kind,
    this.appId,
    this.appDisplayName,
  });

  @override
  List<Object?> get props => [
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

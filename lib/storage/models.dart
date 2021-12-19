import 'dart:isolate';

import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/values.dart';

part 'models.g.dart';

@JsonSerializable()
class DatabaseInfo {
  final String key;
  final String path;
  final SendPort? port;

  const DatabaseInfo({
    this.key = Values.empty,
    this.path = Values.empty,
    this.port,
  });

  Map<String, dynamic> toJson() => _$DatabaseInfoToJson(this);
  factory DatabaseInfo.fromJson(Map<String, dynamic> json) => _$DatabaseInfoFromJson(json);
}

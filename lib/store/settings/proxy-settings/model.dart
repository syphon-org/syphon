import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class ProxySettings extends Equatable {
  final bool enabled; // proxy enabled
  final String host;
  final String port;

  final bool authenticationEnabled; // proxy authentication enabled
  final String username; // proxy username
  final String password; // proxy password

  const ProxySettings({
    this.enabled = false,
    this.host = '127.0.0.1',
    this.port = '8118',
    this.authenticationEnabled = false,
    this.username = 'username',
    this.password = 'password',
  });

  @override
  List<Object?> get props => [
        enabled,
        host,
        port,
        authenticationEnabled,
        username,
        password,
      ];

  ProxySettings copyWith({
    enabled,
    host,
    port,
    authenticationEnabled,
    username,
    password,
  }) =>
      ProxySettings(
        enabled: enabled ?? this.enabled,
        host: host ?? this.host,
        port: port ?? this.port,
        authenticationEnabled: authenticationEnabled ?? this.authenticationEnabled,
        username: username ?? this.username,
        password: password ?? this.password,
      );

  Map<String, dynamic> toJson() => _$ProxySettingsToJson(this);

  factory ProxySettings.fromJson(Map<String, dynamic> json) =>
      _$ProxySettingsFromJson(json);
}

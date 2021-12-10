import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/values.dart';

part 'types.g.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
@JsonSerializable()
class AppContext {
  static const DEFAULT = Values.empty;
  static const ALL_CONTEXT_KEY = '${Values.appLabel}@context-all';
  static const CURRENT_CONTEXT_KEY = '${Values.appLabel}@context-current';

  final String id;
  final String pinHash;
  final String secretKeyEncrypted;

  const AppContext({
    this.id = Values.empty,
    this.pinHash = Values.empty,
    this.secretKeyEncrypted = Values.empty,
  });

  Map<String, dynamic> toJson() => _$AppContextToJson(this);
  factory AppContext.fromJson(Map<String, dynamic> json) => _$AppContextFromJson(json);
}

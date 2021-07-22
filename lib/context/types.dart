import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/global/values.dart';

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
  static const DEFAULT = '';
  static const STORAGE_KEY = '${Values.appLabel}@context';

  final String current;
  final String pinHash;

  AppContext({
    this.current = DEFAULT,
    this.pinHash = DEFAULT,
  });
}

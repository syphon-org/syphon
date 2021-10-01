import 'package:syphon/global/values.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
class AppContext {
  static const DEFAULT = '';
  static const ALL_CONTEXT_KEY = '${Values.appLabel}@context-all';
  static const CURRENT_CONTEXT_KEY = '${Values.appLabel}@context-current';

  final String current;
  final String pinHash;

  AppContext({
    this.current = DEFAULT,
    this.pinHash = DEFAULT,
  });
}

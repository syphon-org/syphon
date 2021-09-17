import 'package:syphon/global/values.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
class StoreContext {
  static const DEFAULT = '';
  static const ACCESS_KEY = '${Values.appLabel}@context';

  final String current;
  final String pinHash;

  StoreContext({
    this.current = DEFAULT,
    this.pinHash = DEFAULT,
  });
}

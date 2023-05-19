import 'package:redux/redux.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/user/actions.dart';
import 'package:syphon/domain/user/storage.dart';
import 'package:syphon/global/libraries/storage/database.dart';
import 'package:syphon/global/print.dart';

///
/// Load Storage Middleware
///
/// Loads storage data from cold storage
/// based  on which redux actions are fired.
///
loadStorageMiddleware(ColdStorageDatabase? storage) {
  return (
    Store<AppState> store,
    // ignore: no_leading_underscores_for_local_identifiers
    dynamic _action,
    NextDispatcher next,
  ) async {
    try {
      if (storage == null) {
        console.warn(
          'storage is null, skipping saving cold storage data!!!',
          title: 'storageMiddleware',
        );
        return;
      }

      switch (_action.runtimeType) {
        case LoadUsers:
          final action = _action as LoadUsers;
          loadUserAsync() async {
            final loadedUsers = await loadUsers(storage: storage, ids: action.userIds ?? []);

            store.dispatch(SetUsers(users: loadedUsers));
          }

          loadUserAsync();
          break;
        default:
          break;
      }
    } catch (error) {
      console.error('[loadStorageMiddleware] $error');
    }

    next(_action);
  };
}

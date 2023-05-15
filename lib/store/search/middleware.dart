import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/events/messages/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/search/actions.dart';

///
/// Storage Middleware
///
/// Saves store data to cold storage based
/// on which redux actions are fired.
///
searchMiddleware(StorageDatabase? coldStorage) {
  return (
    Store<AppState> store,
    dynamic _action,
    NextDispatcher next,
  ) async {
    next(_action);

    if (coldStorage == null) {
      log.warn('storage is null, skipping saving cold storage data!!!', title: 'searchMiddleware');
      return;
    }

    switch (_action.runtimeType) {
      case SearchMessages:
        final action = _action as SearchMessages;
        final results = await searchMessagesStored(action.searchText, storage: coldStorage);
        store.dispatch(SearchMessageResults(results: results));
        break;
      default:
        break;
    }
  };
}

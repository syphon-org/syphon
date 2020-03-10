import 'package:Tether/domain/index.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

/**
 * Send Room Event (Send Message)
 */
ThunkAction<AppState> sendMessage({var body, var type}) {
  return (Store<AppState> store) async {
    print('[sendMessage] ${type} ${body}');
    return true;
  };
}

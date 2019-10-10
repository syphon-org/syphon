import 'package:redux/redux.dart';

initUserAuthentication(Store<int> store, action, NextDispatcher next) {
  print('${new DateTime.now()}: $action');
}

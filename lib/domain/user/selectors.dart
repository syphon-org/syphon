import 'package:Tether/domain/index.dart';

import './model.dart';

dynamic homeserver(AppState state) {
  return state.userStore.homeserver;
}

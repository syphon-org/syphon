// Project imports:
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';

// Preauth

bool creating(AppState state) {
  return state.authStore.creating;
}

bool isLoginAttemptable(AppState state) {
  return state.authStore.isPasswordValid &&
      state.authStore.isUsernameValid &&
      !state.authStore.loading;
}

bool isAuthLoading(AppState state) {
  return state.authStore.loading;
}

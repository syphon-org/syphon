import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/model.dart';

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

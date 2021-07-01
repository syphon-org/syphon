import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/store/index.dart';

// Preauth

bool creating(AppState state) {
  return state.authStore.creating;
}

bool isLoginAttemptable(AppState state) {
  if (state.authStore.homeserver.loginType == MatrixAuthTypes.SSO) {
    return true;
  }

  return state.authStore.isPasswordValid && state.authStore.isUsernameValid && !state.authStore.loading;
}

bool isAuthLoading(AppState state) {
  return state.authStore.loading;
}

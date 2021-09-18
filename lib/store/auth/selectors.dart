import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/store/index.dart';

// Preauth

bool creating(AppState state) {
  return state.authStore.creating;
}

bool selectHasMultiaccount(AppState state) {
  return state.authStore.availableUsers.isNotEmpty;
}

int selectAvailableAccounts(AppState state) {
  return state.authStore.availableUsers.length;
}

bool selectPasswordLoginAttemptable(AppState state) {
  return state.authStore.isPasswordValid &&
      state.authStore.isUsernameValid &&
      !state.authStore.loading &&
      !state.authStore.stopgap;
}

bool selectSSOLoginAttemptable(AppState state) {
  return selectSSOEnabled(state);
}

bool isAuthLoading(AppState state) {
  return state.authStore.loading;
}

bool selectSignupClosed(AppState state) {
  final signupTypes = state.authStore.homeserver.signupTypes;
  return signupTypes.contains(MatrixErrors.forbidden);
}

bool selectPasswordEnabled(AppState state) {
  final loginTypes = state.authStore.homeserver.loginTypes;
  return loginTypes.contains(MatrixAuthTypes.DUMMY) ||
      loginTypes.contains(MatrixAuthTypes.PASSWORD) ||
      loginTypes.isEmpty;
}

bool selectSSOEnabled(AppState state) {
  final loginTypes = state.authStore.homeserver.loginTypes;
  return loginTypes.contains(MatrixAuthTypes.SSO);
}

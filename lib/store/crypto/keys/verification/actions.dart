import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/store/index.dart';

///
/// Send Key Verification Request
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendKeyVerificationRequest(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Key Verification Ready
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendKeyVerificationReady(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Key Verification Start
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendKeyVerificationStart(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Key Verification Accept
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendKeyVerificationAccept(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Key Verification Cancel
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendKeyVerificationCancel(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Key Verification Done
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendKeyVerificationDone(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Verification Key
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendVerificationKey(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

///
/// Send Verification Mac
///
/// https://matrix.org/docs/spec/client_server/latest#key-verification-framework
///
ThunkAction<AppState> sendVerificationMac(Map deviceKeys) {
  return (Store<AppState> store) async {};
}

import 'package:syphon/context/types.dart';

bool selectScreenLockEnabled(AppContext context) {
  return context.pinHash.isNotEmpty && context.secretKeyEncrypted.isNotEmpty;
}

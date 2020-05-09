import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/global/libs/matrix/devices.dart';

abstract class MatrixApi {
  // Authentication
  static const NEEDS_INTERACTIVE_AUTH = Auth.NEEDS_INTERACTIVE_AUTH;

  static final loginUser = Auth.loginUser;
  static final checkUsernameAvailability = Auth.checkUsernameAvailability;
  static final convertInteractiveAuth = Auth.convertInteractiveAuth;

  // Device Management
  static final fetchDevices = Devices.fetchDevices;
  static final updateDevice = Devices.updateDevice;
  static final deleteDevice = Devices.deleteDevice;
  static final deleteDevices = Devices.deleteDevices;
}

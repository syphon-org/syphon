import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/global/libs/matrix/devices.dart';

abstract class MatrixApi {
  // Authentication
  static const NEEDS_INTERACTIVE_AUTH = Auth.NEEDS_INTERACTIVE_AUTH;

  static final loginUser = Auth.loginUser;
  static final logoutUser = Auth.logoutUser;
  static final registerUser = Auth.registerUser;
  static final checkUsernameAvailability = Auth.checkUsernameAvailability;

  // Device Management
  static final fetchDevices = Devices.fetchDevices;
  static final updateDevice = Devices.updateDevice;
  static final deleteDevice = Devices.deleteDevice;
  static final deleteDevices = Devices.deleteDevices;
}

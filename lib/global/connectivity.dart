import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionService {
  static bool checked = false;
  static ConnectivityResult? currentStatus;
  static StreamSubscription<ConnectivityResult>? connectivity;

  static Future<bool> checkConnected() async {
    currentStatus = await Connectivity().checkConnectivity();
    return currentStatus != ConnectivityResult.none;
  }

  static bool isConnected() {
    return currentStatus != null && currentStatus != ConnectivityResult.none;
  }

  static Future startListener() async {
    if (connectivity != null) return;

    currentStatus = await Connectivity().checkConnectivity();

    return connectivity = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      checked = false;
      currentStatus = result;
    });
  }

  static Future<void> stopListener() async {
    if (connectivity != null) {
      await connectivity?.cancel();
      connectivity = null;
    }
  }
}

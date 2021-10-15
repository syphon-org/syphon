import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionService {
  static StreamSubscription<ConnectivityResult>? connectivity;

  static ConnectivityResult? currentStatus;

  static Future startListener() async {
    if (connectivity != null) return;

    return connectivity = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      currentStatus = result;
    });
  }

  static Future<void> stopListener() async {
    if (connectivity != null) {
      await connectivity?.cancel();
      currentStatus = null;
    }
  }
}

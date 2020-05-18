import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/store/rooms/service.isolate.dart';
import 'package:Tether/global/notifications.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'package:Tether/global/libs/matrix/rooms.dart';

Isolate roomObserverIsolate;
SendPort roomObserverSendPort;
final int roomObserverID = 100;

class CrossIsolatesMessage<T> {
  final SendPort sender;
  final T message;

  CrossIsolatesMessage({
    @required this.sender,
    this.message,
  });
}

/**
 * 
 * Android
 * 
 * Android Only - executed in isolates - alarm_manager + local_notifications 
 * https://pub.dev/packages/android_alarm_manager - implement and test
 * https://github.com/seamonkeysocial/rainbowmonkey
 * 
 * Android Only - executed natively
 * https://dev.to/protium/flutter-background-services-19a4
 * 
 * iOS
 * 
 * Signal for iOS interesting impliementations
 * https://github.com/signalapp/Signal-iOS/blob/master/SignalServiceKit/src/Messages/MessageFetcherJob.swift
 * https://github.com/signalapp/Signal-iOS/blob/master/Signal/src/Jobs/SessionResetJob.swift
 * https://github.com/signalapp/Signal-iOS/blob/master/Signal/src/Jobs/ConversationConfigurationSyncOperation.swift
 * 
 * Building an Alarm app on iOS
 * https://stackoverflow.com/questions/14337275/ios-background-process-similar-to-android-alarmmanager
 *
 * Android + iOS
 * 
 * Both but only fires at min 15 minutes
 * https://github.com/vrtdev/flutter_workmanager/blob/master/IOS_SETUP.md#registered-plugins
 * https://pub.dev/packages/background_fetch
 * 
 * Both platforms - pure isolates but force it to remain open on app close?
 * https://github.com/MaikuB/flutter_local_notifications/issues/322
 * 
 * Other
 * 
 * App is open, but run in background with plugins
 * https://medium.com/flutter/executing-dart-in-the-background-with-flutter-plugins-and-geofencing-2b3e40a1a124
 * 
 * Plugins cannot be used from non-ui threads, but android_alarm_manager and local_notifications work together?
 * https://github.com/flutter/flutter/issues/26413
 * 
 * One dev is using a headless flutter view to run dart code in the bg
 * https://github.com/MaikuB/flutter_local_notifications/issues/278
 * 
 * Signal
 * Other Reading
 * https://api.dart.dev/stable/2.0.0/dart-isolate/dart-isolate-library.html
 * https://github.com/flutter/flutter/issues/47212
 * https://github.com/lucmertins/bgnotif/tree/master/lib
 * https://github.com/vrtdev/flutter_workmanager
 * 
 * 
 */
// TODO: extract store for init data

void printHello() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
}

/**
 * startRoomObserverService
 * 
 */
Future<bool> startRoomObserverService() async {
  await AndroidAlarmManager.initialize();

  await AndroidAlarmManager.periodic(
    const Duration(seconds: 5),
    roomObserverID,
    printHello,
  );
}

/**
 * initRoomObserverIsolate
 */
void initRoomObserverIsolate(SendPort callerSendPort) async {
  print('[Isolate] booting up');

  final newIsolateReceivePort = ReceivePort();

  WidgetsFlutterBinding.ensureInitialized();

  FlutterLocalNotificationsPlugin pluginInstance = await initNotifications(
    onSelectNotification: (String payload) {
      print('Isolate Notification was opened ${payload}');
    },
  );
  // showDebugNotification(pluginInstance: pluginInstance);

  final timerTest = (timer) {
    print('[Isolate Timer] ${timer.tick} ${timer.hashCode}');
  };

  var testingFetchTimer = Timer.periodic(Duration(seconds: 10), timerTest);

  // Provide the caller with the reference of THIS isolate's SendPort
  callerSendPort.send(newIsolateReceivePort.sendPort);

  // Isolate main routine that listens to incoming messages,
  // processes it and provides an answer
  newIsolateReceivePort.listen((dynamic message) {
    if (message == null) {
      print('[Isolate] shutting down');
      return;
    }

    CrossIsolatesMessage incomingMessage = message as CrossIsolatesMessage;

    // Process the message
    String newMessage = "[Isolate Listener] sent message" + message.message;

    if (testingFetchTimer.isActive) {
      print('[Isolate Timer] Toggling Off');
      testingFetchTimer.cancel();
    } else {
      print('[Isolate Timer] Toggling On');
      testingFetchTimer = Timer.periodic(Duration(seconds: 5), timerTest);
    }
    // Sends the outcome of the processing
    incomingMessage.sender.send(newMessage);
  });
}

void stopRoomObserverService() {
  roomObserverIsolate?.kill(priority: Isolate.immediate);
  roomObserverIsolate = null;
}

Future<dynamic> sendServiceAction(String message) async {
  // We create a temporary port to receive the answer
  ReceivePort port = ReceivePort();

  // We send the message to the Isolate, and also
  // tell the isolate which port to use to provide
  // any answer
  roomObserverSendPort.send(CrossIsolatesMessage<String>(
    sender: port.sendPort,
    message: message,
  ));

  // Wait for the answer and return it
  return port.first;
}

Future<String> fetchSyncNative({
  String since,
  String protocol,
  String homeserver,
  String accessToken,
  bool fullState,
}) async {
  final data = await MatrixApi.sync(
    protocol: protocol,
    homeserver: homeserver,
    accessToken: accessToken,
    fullState: fullState,
    since: since,
  );

  final Map<String, dynamic> rawRooms = data['rooms']['join'];
  final String lastSince = data['next_batch'];

  print('${rawRooms}, ${lastSince}');
  print('Isolate Run completed');

  // TODO: return as json / save diff to local cache
}

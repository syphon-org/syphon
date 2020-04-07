import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:Tether/global/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'package:Tether/global/libs/matrix/rooms.dart';

Isolate roomObserverIsolate;
SendPort roomObserverSendPort;

class CrossIsolatesMessage<T> {
  final SendPort sender;
  final T message;

  CrossIsolatesMessage({
    @required this.sender,
    this.message,
  });
}

// TODO: extract store for init data
Future<bool> startRoomObserverService() async {
  // Dispatch Background Sync

  ReceivePort receivePort = ReceivePort();
  // Whatever is passed in as second param is the arg in the callback
  roomObserverIsolate = await Isolate.spawn(
    initRoomObserverIsolate,
    receivePort.sendPort,
  );

  roomObserverSendPort = await receivePort.first;
}

// To be called by the isolate on start
void initRoomObserverIsolate(SendPort callerSendPort) async {
  final newIsolateReceivePort = ReceivePort();

  FlutterLocalNotificationsPlugin pluginInstance = await initNotifications(
    onSelectNotification: (String payload) {
      print('Isolate Notification was opened ${payload}');
    },
  );

  final timerTest = (timer) {
    showDebugNotification(pluginInstance: pluginInstance);
    print(
      '[Isolate Timer] ${timer.tick} ${timer.hashCode}',
    );
  };

  var testingFetchTimer = Timer.periodic(Duration(seconds: 10), timerTest);

  // Provide the caller with the reference of THIS isolate's SendPort
  callerSendPort.send(newIsolateReceivePort.sendPort);

  // Isolate main routine that listens to incoming messages,
  // processes it and provides an answer
  newIsolateReceivePort.listen((dynamic message) {
    CrossIsolatesMessage incomingMessage = message as CrossIsolatesMessage;

    // Process the message
    String newMessage = "[Isolate Listener] sent message" + message.message;

    print(newMessage);

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
  final request = buildSyncRequest(
    protocol: protocol,
    homeserver: homeserver,
    accessToken: accessToken,
    fullState: fullState,
    since: since,
  );

  final response = await http.get(
    request['url'],
    headers: request['headers'],
  );

  // parse sync data
  final data = json.decode(response.body);
  final Map<String, dynamic> rawRooms = data['rooms']['join'];
  final String lastSince = data['next_batch'];

  print('${rawRooms}, ${lastSince}');
  print('Isolate Run completed');

  // TODO: return as json / save diff to local cache
}

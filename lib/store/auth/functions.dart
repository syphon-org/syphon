import 'dart:async';
import 'dart:io';

import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;

StreamSubscription _sub;

Future<Null> initUniLinks() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    String initialLink = await getInitialLink();
    print('[initUniLinks] ${initialLink}');

    // Attach a listener to the stream
    _sub = getUriLinksStream().listen((Uri uri) {
      print('[streamUniLinks] ${uri}');
      // Use the uri and warn the user, if it is not correct
    }, onError: (err) {
      print('[streamUniLinks] error ${err}');
      // Handle exception by warning the user their action did not succeed
    });

    // Parse the link and warn the user, if it is not correct,
    // but keep in mind it could be `null`.
  } on PlatformException {
    // Handle exception by warning the user their action did not succeed
    // return?
  }
}

Future<Null> disposeUniLinks() async {
  try {
    _sub.cancel();
  } catch (error) {}
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:syphon/global/values.dart';

/*
 * Captcha
 * renders the captcha needed to be completed 
 * by certain matrix servers -_-
 */
class Captcha extends StatefulWidget {
  final String? publicKey;
  final Function onVerified;

  const Captcha({
    Key? key,
    required this.publicKey,
    required this.onVerified,
  }) : super(
          key: key,
        );

  @override
  CaptchaState createState() => CaptchaState(
        publickey: publicKey,
        onVerified: onVerified,
      );
}

class CaptchaState extends State<Captcha> {
  final String? publickey;
  final Function? onVerified;

  final Completer<WebViewController> controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();

    // NOTE: SchedulerBinding still needed to have navigator context in dialogs
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    // Confirm public key is correct
    // debugPrint('[captcha wrapper] ${this.publickey}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  CaptchaState({
    this.publickey,
    this.onVerified,
  });

  // Matrix Public Key
  @override
  Widget build(BuildContext context) {
    final captchaUrl = '${Values.captchaUrl}$publickey';

    return WebView(
      initialUrl: captchaUrl,
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        JavascriptChannel(
          name: 'RecaptchaFlutterChannel',
          onMessageReceived: (JavascriptMessage receiver) {
            String token = receiver.message;
            if (token.contains('verify')) {
              token = token.substring(7);
            }
            if (onVerified != null) {
              onVerified!(token);
            }
          },
        ),
      },
      onWebViewCreated: (WebViewController webViewController) {
        controller.complete(webViewController);
      },
    );
  }
}

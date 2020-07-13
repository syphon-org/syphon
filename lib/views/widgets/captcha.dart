import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_recaptcha_v2/flutter_recaptcha_v2.dart';
import 'package:syphon/global/values.dart';
import 'package:webview_flutter/webview_flutter.dart';

/**
 * Captcha
 * renders the captcha needed to be completed 
 * by certain matrix servers -_-
 * 
 * TODO: find out how t ouse recaptcha with public key
 */
class Captcha extends StatefulWidget {
  final String publicKey;
  final Function onVerified;

  const Captcha({
    Key key,
    @required this.publicKey,
    @required this.onVerified,
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
  final String publickey;
  final Function onVerified;

  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();
  final Completer<WebViewController> controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    recaptchaV2Controller.show();

    // Confirm public key is correct
    // debugPrint('[captcha wrapper] ${this.publickey}');
  }

  @override
  void dispose() {
    recaptchaV2Controller.dispose();
    super.dispose();
  }

  CaptchaState({
    Key key,
    this.publickey,
    this.onVerified,
  });

  // Matrix Public Key
  @override
  Widget build(BuildContext context) {
    final captchaUrl = '${Values.captchaUrl}${this.publickey}';

    return Container(
      child: WebView(
        initialUrl: captchaUrl,
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: <JavascriptChannel>[
          JavascriptChannel(
            name: 'RecaptchaFlutterChannel',
            onMessageReceived: (JavascriptMessage receiver) {
              String token = receiver.message;
              if (token.contains("verify")) {
                token = token.substring(7);
              }
              if (this.onVerified != null) {
                this.onVerified(token);
              }
            },
          ),
        ].toSet(),
        onWebViewCreated: (WebViewController webViewController) {
          controller.complete(webViewController);
        },
      ),
    );
  }
}

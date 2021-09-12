import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:syphon/global/values.dart';

/*
 * Captcha
 * renders the captcha needed to be completed 
 * by certain matrix servers -_-
 */
class Captcha extends StatefulWidget {
  final String? baseUrl;
  final String? publicKey;
  final Function onVerified;

  const Captcha({
    Key? key,
    required this.baseUrl,
    required this.publicKey,
    required this.onVerified,
  }) : super(
          key: key,
        );

  @override
  CaptchaState createState() => CaptchaState();
}

class CaptchaState extends State<Captcha> with Lifecycle<Captcha> {
  WebViewController? controller;

  CaptchaState();

  loadLocalHtml() async {
    final recaptchaHTML = await rootBundle.loadString(Assets.captchaHTML);
    final recaptchaWithSiteKeyHTML = recaptchaHTML.replaceFirst(
      's%',
      widget.publicKey ?? Values.captchaMatrixSiteKey,
    );

    controller?.loadHtml(recaptchaWithSiteKeyHTML);
  }

  // Matrix Public Key
  @override
  Widget build(BuildContext context) {
    return WebView(
      baseUrl: widget.baseUrl != null ? 'https://${widget.baseUrl}' : 'https://matrix.org',
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        JavascriptChannel(
          name: 'Captcha',
          onMessageReceived: (JavascriptMessage message) {
            String token = message.message;
            if (token.contains('verify')) {
              token = token.substring(7);
            }
            widget.onVerified(token);
          },
        ),
      },
      onWebViewCreated: (WebViewController webViewController) {
        controller = webViewController;
        loadLocalHtml();
      },
    );
  }
}

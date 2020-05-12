import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_recaptcha_v2/flutter_recaptcha_v2.dart';

/**
 * Captcha
 * renders the captcha needed to be completed 
 * by certain matrix servers -_-
 * 
 * TODO: find out how t ouse recaptcha with public key
 */
class Captcha extends StatefulWidget {
  final String publicKey;

  const Captcha({
    Key key,
    @required this.publicKey,
  }) : super(
          key: key,
        );

  @override
  CaptchaState createState() => CaptchaState(
        publickey: publicKey,
      );
}

class CaptchaState extends State<Captcha> {
  final String publickey;

  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();
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
    print('[captcha wrapper] ${this.publickey}');
  }

  @override
  void dispose() {
    recaptchaV2Controller.dispose();
    super.dispose();
  }

  CaptchaState({
    Key key,
    this.publickey,
  });

  // Matrix Public Key
  // 6LcgI54UAAAAABGdGmruw6DdOocFpYVdjYBRe4zb
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.red,
        child: Stack(
          overflow: Overflow.visible,
          children: <Widget>[
            RecaptchaV2(
              apiKey:
                  '6LcgI54UAAAAABGdGmruw6DdOocFpYVdjYBRe4zb', // for enabling the reCaptcha
              apiSecret:
                  "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe", // for verifying the responded token
              controller: recaptchaV2Controller,
              onVerifiedError: (err) {
                print(err);
              },
              onVerifiedSuccessfully: (success) {
                setState(() {
                  if (success) {
                    print('You\'ve been verified successfully.');
                  } else {
                    print('Failed to verify.');
                  }
                });
              },
            ),
          ],
        ));
  }
}

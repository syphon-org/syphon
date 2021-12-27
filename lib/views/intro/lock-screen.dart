import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syphon/context/auth.dart';
import 'package:syphon/context/types.dart';

import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/prelock.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/show-lock-overlay.dart';

///
/// Lock Screen
///
/// Shows a background Loading Screen
/// with a pin locked overlay for the user to solve
///
class LockScreen extends StatefulWidget {
  final AppContext appContext;

  const LockScreen({
    Key? key,
    required this.appContext,
  }) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with Lifecycle<LockScreen> {
  int maxRetries = 3;

  String pinVerified = '';

  @override
  void onMounted() {
    showLockOverlay(
        context: context,
        canCancel: false,
        onMaxRetries: onMaxRetries,
        maxRetries: maxRetries,
        onVerify: (String answer) async {
          return Future.value(verifyPinHashIsolate(
            passcode: answer,
            hash: widget.appContext.pinHash,
          ));
        },
        onUnlocked: (String pin) {
          Prelock.toggleLocked(context, pin);
          Navigator.of(context).pop();
        });
  }

  onMaxRetries(int retries) {
    if (retries > maxRetries) {
      // preferred over exit(0) to not mistaken as a crash
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen(dark: Platform.isAndroid);
  }
}

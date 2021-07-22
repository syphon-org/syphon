import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/handlers.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/views/applock.dart';

import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/prelock.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/show-lock-overlay.dart';

class LockScreen extends StatefulWidget {
  final AppContext appContext;

  const LockScreen({
    Key? key,
    required this.appContext,
  }) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  int maxRetries = 3;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      onMounted();
    });
  }

  onMounted() {
    showLockOverlay(
        context: context,
        canCancel: false,
        onMaxRetries: onMaxRetries,
        maxRetries: maxRetries,
        onVerify: (String answer) async {
          return Future.value(true);
          return Future.value(verifyPinHash(
            passcode: answer,
            hash: widget.appContext.pinHash,
          ));
        },
        onUnlocked: () async {
          Prelock.togglePermitted(context);
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
    return LoadingScreen(lite: true);
  }
}

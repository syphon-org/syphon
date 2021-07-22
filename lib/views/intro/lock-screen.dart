import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:syphon/context/handlers.dart';
import 'package:syphon/context/types.dart';

import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/prelock.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/show-lock-overlay.dart';

class LockScreen extends StatefulWidget {
  final AppContext appContext;
  final bool enabled;
  final Widget child;

  const LockScreen({
    Key? key,
    required this.appContext,
    required this.enabled,
    required this.child,
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

  onMounted() async {
    if (!widget.enabled) {
      await Prelock.togglePermitted(context);
      return;
      // return AppLock.of(context)!.didUnlock();
    }

    showLockOverlay(
      context: context,
      canCancel: false,
      onMaxRetries: onMaxRetries,
      maxRetries: maxRetries,
      onVerify: (String answer) async {
        return Future.value(verifyPinHash(
          passcode: answer,
          hash: widget.appContext.pinHash,
        ));
      },
      onUnlocked: () async {
        await Prelock.togglePermitted(context);
        // return AppLock.of(context)!.didUnlock();
        return;
      },
    );
  }

  onMaxRetries(int retries) {
    if (retries > maxRetries) {
      // preferred over exit(0) to not mistaken as a crash
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: Key(widget.enabled.toString()),
      children: [
        widget.child,
        Visibility(
          visible: widget.enabled,
          maintainSize: false,
          child: LoadingScreen(),
        ),
      ],
    );
  }
}

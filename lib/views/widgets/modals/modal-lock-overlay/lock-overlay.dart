import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/configurations/input_button_config.dart';
import 'package:flutter_screen_lock/configurations/screen_lock_config.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/input-secrets-config.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/input-secrets.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/keypad.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/lock-controller.dart';

class LockOverlay extends StatefulWidget {
  const LockOverlay({
    Key? key,
    required this.onVerify,
    required this.title, // i18n Strings isn't a constant. You gotta pass it in
    required this.confirmTitle, // i18n Strings isn't a constant. You gotta pass it in
    this.screenLockConfig = const ScreenLockConfig(),
    this.inputSecretsConfig = const InputSecretsConfig(),
    this.inputButtonConfig = const InputButtonConfig(),
    this.canCancel = true,
    this.confirmMode = false,
    this.maxLength = 9,
    this.maxRetries = 0,
    this.onUnlocked,
    this.onConfirmed,
    this.onError,
    this.onMaxRetires,
    this.onLeftButtonTap,
    this.rightButtonChild,
    this.footer,
    this.cancelButton,
    this.deleteButton,
    this.lockController,
  })  : assert(maxRetries > -1),
        super(key: key);

  /// Configurations of [ScreenLock].
  final ScreenLockConfig screenLockConfig;

  /// Configurations of [Secrets].
  final InputSecretsConfig inputSecretsConfig;

  /// Configurations of [InputButton].
  final InputButtonConfig inputButtonConfig;

  /// Heading title for ScreenLock.
  final Widget title;

  /// Heading confirm title for ScreenLock.
  final Widget confirmTitle;

  /// You can cancel and close the ScreenLock.
  final bool canCancel;

  /// Make sure the first and second inputs are the same.
  final bool confirmMode;

  /// Set the maximum number of characters to enter when confirmation is true.
  final int maxLength;

  /// `0` is unlimited.
  /// For example, if it is set to 1, didMaxRetries will be called on the first failure.
  final int maxRetries;

  /// Called if the value matches the correctString.
  ///
  /// To close the screen, call `Navigator.pop(context)`.
  final void Function(String pin)? onUnlocked;

  /// Called when the first and second inputs match during confirmation.
  ///
  /// To close the screen, call `Navigator.pop(context)`.
  final void Function(String matchedText)? onConfirmed;

  /// Called if the value does not match the correctString.
  final void Function(int retries)? onError;

  /// Events that have reached the maximum number of attempts.
  final void Function(int retries)? onMaxRetires;

  /// Events that have reached the maximum number of attempts.
  final Future<bool> Function(String input) onVerify;

  /// Tapped for left side lower button.
  final Future<void> Function()? onLeftButtonTap;

  /// Child for bottom right side button.
  final Widget? rightButtonChild;

  /// Footer widget.
  final Widget? footer;

  /// Cancel button widget.
  final Widget? cancelButton;

  /// delete button widget.
  final Widget? deleteButton;

  /// Control inputs externally.
  final LockController? lockController;

  @override
  _LockOverlayState createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay> {
  late LockController lockController;

  int retries = 1;
  bool unlocking = false;
  String currentInput = '';

  void unlocked(String pin) {
    if (widget.onUnlocked != null) {
      widget.onUnlocked!(pin);
      return;
    }

    Navigator.pop(context);
  }

  void error() {
    if (widget.onError != null) {
      widget.onError!(retries);
    }

    if (widget.maxRetries >= 1 && widget.maxRetries <= retries) {
      widget.onMaxRetires!(retries);
    }

    retries++;
  }

  Widget buildHeadingText() {
    if (widget.confirmMode) {
      return StreamBuilder<bool>(
        stream: lockController.confirmed,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!) {
            return widget.confirmTitle;
          }
          return widget.title;
        },
      );
    }

    return widget.title;
  }

  ThemeData makeThemeData() {
    if (widget.screenLockConfig.themeData != null) {
      return widget.screenLockConfig.themeData!;
    }

    return ScreenLockConfig.defaultThemeData;
  }

  @override
  void initState() {
    super.initState();
    lockController = widget.lockController ?? LockController();
    lockController.initialize(
      maxLength: widget.maxLength,
      onVerifyInput: widget.onVerify,
      isConfirmMode: widget.confirmMode,
    );

    lockController.currentInput.listen((event) {
      setState(() {
        currentInput = event;
      });
    });

    lockController.verifyInput.listen((success) async {
      if (!success) {
        error();

        // Wait for the animation on failure.
        return Future.delayed(const Duration(milliseconds: 300), () {
          lockController.clear();
        });
      }

      if (widget.onConfirmed != null) {
        widget.onConfirmed!(
          lockController.confirmedInput.isEmpty ? currentInput : lockController.confirmedInput,
        );
      }

      if (unlocking || widget.confirmMode) return;

      unlocking = true;

      return unlocked(currentInput);
    });
  }

  @override
  void dispose() {
    lockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.canCancel,
      child: Theme(
        data: makeThemeData(),
        child: Scaffold(
          backgroundColor: widget.screenLockConfig.backgroundColor,
          body: SafeArea(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildHeadingText(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: InputSecrets(
                        length: currentInput.length,
                        config: widget.inputSecretsConfig,
                        inputStream: lockController.currentInput,
                        verifyStream: lockController.verifyInput,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: KeyPad(
                        inputButtonConfig: widget.inputButtonConfig,
                        lockController: lockController,
                        canCancel: widget.canCancel,
                        onLeftButtonTap: widget.onLeftButtonTap,
                        rightButtonChild: widget.rightButtonChild,
                        deleteButton: widget.deleteButton,
                        cancelButton: widget.cancelButton,
                      ),
                    ),
                    widget.footer ?? Container(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

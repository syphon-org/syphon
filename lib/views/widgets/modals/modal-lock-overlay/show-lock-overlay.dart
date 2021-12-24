import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/configurations/input_button_config.dart';
import 'package:flutter_screen_lock/configurations/screen_lock_config.dart';
import 'package:flutter_screen_lock/heading_title.dart';
import 'package:flutter_screen_lock/screen_lock.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/input-secrets-config.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/lock-controller.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/lock-overlay.dart';

/// Animated ScreenLock
///
/// - `correctString`: Input correct string (Required).
///   If [confirmMode] is `true`, it will be ignored, so set it to any string or empty.
/// - `screenLockConfig`: Configurations of [ScreenLock]
/// - `secretsConfig`: Configurations of [Secrets]
/// - `inputButtonConfig`: Configurations of [InputButton]
/// - `canCancel`: `true` is show cancel button
/// - `confirmation`: Make sure the first and second inputs are the same.
/// - `digits`: Set the maximum number of characters to enter when [confirmMode] is `true`.
/// - `maxRetries`: `0` is unlimited. For example, if it is set to 1, didMaxRetries will be called on the first failure. Default `0`
/// - `didUnlocked`: Called if the value matches the correctString.
/// - `didError`: Called if the value does not match the correctString.
/// - `didMaxRetries`: Events that have reached the maximum number of attempts
/// - `didOpened`: For example, when you want to perform biometric authentication
/// - `didConfirmed`: Called when the first and second inputs match during confirmation
/// - `customizedButtonTap`: Tapped for left side lower button
/// - `customizedButtonChild`: Child for bottom left side button
/// - `footer`: Add a Widget to the footer
/// - `cancelButton`: Change the child widget for the delete button
/// - `deleteButton`: Change the child widget for the delete button
/// - `title`: Change the title widget
/// - `confirmTitle`: Change the confirm title widget
/// - `inputController`: Control inputs externally
Future<T>? showLockOverlay<T>({
  required BuildContext context,
  required Future<bool> Function(String) onVerify,
  ScreenLockConfig screenLockConfig = const ScreenLockConfig(),
  InputSecretsConfig secretsConfig = const InputSecretsConfig(),
  InputButtonConfig inputButtonConfig = const InputButtonConfig(),
  bool canCancel = true,
  bool confirmMode = false,
  int digits = 9,
  int maxRetries = 0,
  LockController? lockController,
  void Function(String pin)? onUnlocked,
  void Function(int retries)? onError,
  void Function(int retries)? onMaxRetries,
  void Function()? onOpened,
  void Function(String matchedText)? onConfirmed,
  Future<void> Function()? onLeftButtonTap,
  Widget? rightButtonChild,
  Widget? footer,
  Widget? cancelButton,
  Widget? deleteButton,
  Widget title = const HeadingTitle(text: 'Please enter your passcode.'),
  Widget confirmTitle = const HeadingTitle(text: 'Please enter confirm passcode.'),
}) {
  Navigator.push(
    context,
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.8),
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secodaryAnimation,
      ) {
        animation.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (onOpened != null) {
              onOpened();
            }
          }
        });
        return LockOverlay(
          screenLockConfig: screenLockConfig,
          inputSecretsConfig: secretsConfig,
          inputButtonConfig: inputButtonConfig,
          canCancel: canCancel,
          confirmMode: confirmMode,
          maxLength: digits,
          maxRetries: maxRetries,
          onUnlocked: onUnlocked,
          onError: onError,
          onMaxRetires: onMaxRetries,
          onConfirmed: onConfirmed,
          onVerify: onVerify,
          onLeftButtonTap: onLeftButtonTap,
          rightButtonChild: rightButtonChild,
          footer: footer,
          deleteButton: deleteButton,
          cancelButton: cancelButton,
          title: title,
          confirmTitle: confirmTitle,
          lockController: lockController,
        );
      },
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 2.4),
            end: Offset.zero,
          ).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.0, 2.4),
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
    ),
  );
}

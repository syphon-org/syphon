import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/keys/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/devices-settings/selectors.dart';
import 'package:syphon/store/settings/selectors.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/syphon.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm-password.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/show-lock-overlay.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  onConfirmDeactivateAccount({
    required _Props props,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Deactivate Account',
        content: Strings.warningDeactivateAccount,
        confirmText: Strings.buttonDeactivate.capitalize(),
        confirmStyle: TextStyle(color: Colors.red),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          props.onResetConfirmAuth();
          onConfirmDeactivateAccountFinal(props: props, context: context);
        },
      ),
    );
  }

  onConfirmDeactivateAccountFinal({
    required _Props props,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Deactivate Account Final',
        content: Strings.warrningDeactivateAccountFinal,
        loading: props.loading,
        confirmText: Strings.buttonDeactivate.capitalize(),
        confirmStyle: TextStyle(color: Colors.red),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          await props.onDeactivateAccount(context);
        },
      ),
    );
  }

  onExportDeviceKey({
    required _Props props,
    required BuildContext context,
  }) async {
    final store = StoreProvider.of<AppState>(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Exporting Keys',
        content: Strings.contentKeyExportWarning,
        loading: props.loading,
        confirmText: 'Export Keys',
        confirmStyle: TextStyle(color: Theme.of(context).primaryColor),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          await store.dispatch(exportDeviceKeysOwned());
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  onDeleteDeviceKey({
    required _Props props,
    required BuildContext context,
  }) async {
    final store = StoreProvider.of<AppState>(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.titleConfirmDeleteKeys,
        content: Strings.confirmDeleteKeys,
        loading: props.loading,
        confirmText: 'Delete Keys',
        confirmStyle: TextStyle(color: Colors.red),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          await store.dispatch(deleteDeviceKeys());
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  onSetScreenLockPin({
    required _Props props,
    required BuildContext context,
  }) {
    if (props.screenLockEnabled) {
      return showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: 'Remove Screen Lock',
          content:
              'Are you sure you want to remove the screen lock? This will also remove the pin protection of the cache',
          loading: props.loading,
          confirmText: 'Remove',
          confirmStyle: TextStyle(color: Colors.red),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            Navigator.of(dialogContext).pop();

            showLockOverlay(
              context: context,
              canCancel: true,
              maxRetries: 0,
              onMaxRetries: (stuff) {
                Navigator.of(context).pop();
              },
              onLeftButtonTap: () {
                Navigator.of(context).pop();
                return Future.value();
              },
              title: Text('Enter your current screen lock pin'),
              onVerify: (String answer) async {
                return Future.value(true);
              },
              onConfirmed: (String matchedText) async {
                await props.onRemoveScreenLock(matchedText);
                Syphon.reloadCurrentContext(context);
              },
            );
          },
        ),
      );
    }

    return showLockOverlay(
      context: context,
      canCancel: true,
      confirmMode: true,
      onLeftButtonTap: () {
        Navigator.of(context).pop();
        return Future.value();
      },
      title: Text('Enter your new screen lock pin'),
      confirmTitle: Text('Enter your pin again to verify'),
      onVerify: (String answer) async {
        return Future.value(true);
      },
      onConfirmed: (String matchedText) async {
        await props.onSetScreenLock(matchedText);
        Syphon.reloadCurrentContext(context);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(
          store,
          Syphon.getAppContext(context),
        ),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBarNormal(title: Strings.titlePrivacy),
            body: SingleChildScrollView(
                padding: Dimensions.scrollviewPadding,
                child: Column(
                  children: <Widget>[
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              Strings.titleVerification,
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Public Device Name',
                            ),
                            subtitle: Text(
                              props.sessionName,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Session ID',
                            ),
                            subtitle: Text(
                              props.sessionId,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Session Key',
                            ),
                            subtitle: Text(
                              props.sessionKey,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'User Access',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.settingsPassword);
                            },
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Change Password',
                            ),
                            subtitle: Text(
                              'Changing your password will refresh your\ncurrent session',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.settingsBlocked);
                            },
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Blocked Users',
                            ),
                            subtitle: Text(
                              'View and manage blocked users',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'Communication',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () => props.onIncrementReadReceipts(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Read Receipts',
                            ),
                            subtitle: Text(
                              'If read receipts are disabled or hidden, users will not see solid read indicators for your messages.',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Text(props.readReceipts),
                          ),
                          ListTile(
                            onTap: () => props.onToggleTypingIndicators(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Typing Indicators',
                            ),
                            subtitle: Text(
                              'If typing indicators are disabled, you won\'t be able to see typing indicators from others',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.typingIndicators!,
                              onChanged: (enterSend) => props.onToggleTypingIndicators(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'App access',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Screen lock',
                            ),
                            subtitle: Text(
                              'Lock ${Values.appName} access with native device screen lock or fingerprint',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.screenLockEnabled,
                              onChanged: (enabled) =>
                                  onSetScreenLockPin(props: props, context: context),
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Screen lock inactivity timeout',
                            ),
                            subtitle: Text(
                              'None',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'Encryption Keys',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => props.onDisabled(),
                            child: ListTile(
                              enabled: false,
                              onTap: props.onImportDeviceKey as void Function()?,
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Import Keys',
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => props.onDisabled(),
                            child: ListTile(
                              enabled: false,
                              onTap: () => onExportDeviceKey(context: context, props: props),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Export Keys',
                              ),
                            ),
                          ),
                          ListTile(
                            onTap: () => onDeleteDeviceKey(context: context, props: props),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Delete Keys',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: Dimensions.listPadding,
                            child: Text(
                              'Account Management',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () => onConfirmDeactivateAccount(
                              props: props,
                              context: context,
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Deactivate Account',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool? typingIndicators;
  final bool screenLockEnabled;

  final String sessionId;
  final String sessionName;
  final String sessionKey;
  final String readReceipts;

  final Function onToggleTypingIndicators;
  final Function onIncrementReadReceipts;
  final Function onImportDeviceKey;
  final Function onDisabled;
  final Function onDeactivateAccount;
  final Function onResetConfirmAuth;
  final Function onSetScreenLock;
  final Function onRemoveScreenLock;

  const _Props({
    required this.loading,
    required this.readReceipts,
    required this.screenLockEnabled,
    required this.typingIndicators,
    required this.sessionId,
    required this.sessionName,
    required this.sessionKey,
    required this.onDisabled,
    required this.onToggleTypingIndicators,
    required this.onIncrementReadReceipts,
    required this.onImportDeviceKey,
    required this.onDeactivateAccount,
    required this.onResetConfirmAuth,
    required this.onSetScreenLock,
    required this.onRemoveScreenLock,
  });

  @override
  List<Object?> get props => [
        loading,
        typingIndicators,
        readReceipts,
        sessionId,
        sessionName,
        sessionKey,
        screenLockEnabled
      ];

  static _Props mapStateToProps(Store<AppState> store, AppContext context) => _Props(
        loading: store.state.authStore.loading,
        screenLockEnabled: selectScreenLockEnabled(context),
        typingIndicators: store.state.settingsStore.typingIndicatorsEnabled,
        readReceipts: selectReadReceiptsString(store.state.settingsStore.readReceipts),
        sessionId: store.state.authStore.user.deviceId ?? Values.empty,
        sessionName: selectCurrentDeviceName(store),
        sessionKey: selectCurrentUserSessionKey(store),
        onSetScreenLock: (String matchedPin) async =>
            await store.dispatch(setScreenLock(pin: matchedPin)),
        onRemoveScreenLock: (String matchedPin) async =>
            await store.dispatch(removeScreenLock(pin: matchedPin)),
        onDisabled: () => store.dispatch(addInProgress()),
        onResetConfirmAuth: () => store.dispatch(resetInteractiveAuth()),
        onToggleTypingIndicators: () => store.dispatch(toggleTypingIndicators()),
        onIncrementReadReceipts: () => store.dispatch(incrementReadReceipts()),
        onImportDeviceKey: () => store.dispatch(importDeviceKeysOwned()),
        onDeactivateAccount: (BuildContext context) async {
          // Attempt to deactivate account
          await store.dispatch(deactivateAccount());

          // Prompt for password if an Interactive Auth sessions was started
          final authSession = store.state.authStore.authSession;
          if (authSession != null) {
            showDialog(
              context: context,
              builder: (dialogContext) => DialogConfirmPassword(
                key: Key(authSession),
                title: Strings.titleConfirmPassword,
                content: Strings.confirmDeactivate,
                onConfirm: () async {
                  await store.dispatch(deactivateAccount());
                  Navigator.of(dialogContext).pop();
                },
                onCancel: () async {
                  Navigator.of(dialogContext).pop();
                },
              ),
            );
          }
        },
      );
}

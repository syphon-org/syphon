import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';

import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm-password.dart';
import 'package:syphon/views/widgets/loader/loading-indicator.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  onConfirmDeactivateAccount({
    required _Props props,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm Deactivate Account'),
        content: Text(Strings.warningDeactivateAccount),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              Strings.buttonCancel,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              props.onResetConfirmAuth();
              onConfirmDeactivateAccountFinal(props: props, context: context);
            },
            child: Text(
              Strings.buttonConfirm,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  onConfirmDeactivateAccountFinal({
    required _Props props,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm Deactivate Account'),
        content: Text(Strings.warrningDeactivateAccountFinal),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              Strings.buttonCancel,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await props.onDeactivateAccount(context);
            },
            child: props.loading
                ? LoadingIndicator()
                : Text(
                    Strings.buttonDeactivate,
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  onConfirmAuth() {}

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titlePrivacy,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
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
                              'App access',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Screen lock',
                            ),
                            subtitle: Text(
                              'Lock ${Values.appName} access with native device screen lock or fingerprint',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: false,
                              onChanged: null,
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
                              'User Access',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, NavigationPaths.settingsPassword);
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
                              Navigator.pushNamed(context, NavigationPaths.settingsBlocked);
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
                            onTap: () => props.onToggleReadReceipts(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Read Receipts',
                            ),
                            subtitle: Text(
                              'If read receipts are disabled, users will not see solid read indicators for your messages.',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.readReceipts!,
                              onChanged: (enterSend) => props.onToggleReadReceipts(),
                            ),
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
                              onTap: () => props.onExportDeviceKey(context),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Export Keys',
                              ),
                            ),
                          ),
                          ListTile(
                            onTap: () => props.onDeleteDeviceKey(context),
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
  final bool? readReceipts;
  final bool? typingIndicators;

  final Function onToggleTypingIndicators;
  final Function onToggleReadReceipts;
  final Function onExportDeviceKey;
  final Function onImportDeviceKey;
  final Function onDeleteDeviceKey;
  final Function onDisabled;
  final Function onDeactivateAccount;
  final Function onResetConfirmAuth;

  const _Props({
    required this.loading,
    required this.readReceipts,
    required this.typingIndicators,
    required this.onDisabled,
    required this.onToggleTypingIndicators,
    required this.onToggleReadReceipts,
    required this.onExportDeviceKey,
    required this.onImportDeviceKey,
    required this.onDeleteDeviceKey,
    required this.onDeactivateAccount,
    required this.onResetConfirmAuth,
  });

  @override
  List<Object?> get props => [
        loading,
        typingIndicators,
        readReceipts,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        typingIndicators: store.state.settingsStore.typingIndicatorsEnabled,
        readReceipts: store.state.settingsStore.readReceiptsEnabled,
        onDisabled: () => store.dispatch(addInProgress()),
        onResetConfirmAuth: () => store.dispatch(resetInteractiveAuth()),
        onDeactivateAccount: (BuildContext context) async {
          // Attempt to deactivate account
          await store.dispatch(deactivateAccount());

          // Prompt for password if an Interactive Auth sessions was started
          final authSession = store.state.authStore.session;
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
        onToggleTypingIndicators: () => store.dispatch(
          toggleTypingIndicators(),
        ),
        onToggleReadReceipts: () => store.dispatch(
          toggleReadReceipts(),
        ),
        onImportDeviceKey: () {
          store.dispatch(importDeviceKeysOwned());
        },
        onExportDeviceKey: (BuildContext context) async {
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('Confirm Exporting Keys'),
              content: Text(Strings.contentKeyExportWarning),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(Strings.buttonCancel),
                ),
                TextButton(
                  onPressed: () async {
                    store.dispatch(exportDeviceKeysOwned());
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Export Keys',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        onDeleteDeviceKey: (BuildContext context) async {
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(Strings.titleConfirmDeleteKeys),
              content: Text(Strings.confirmDeleteKeys),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    Strings.buttonCancel,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await store.dispatch(deleteDeviceKeys());
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    Strings.buttonTextDeleteKeys,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: Colors.redAccent,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

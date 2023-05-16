// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:syphon/domain/alerts/actions.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/domain/crypto/actions.dart';
import 'package:syphon/domain/crypto/keys/selectors.dart';
import 'package:syphon/domain/crypto/sessions/actions.dart';
import 'package:syphon/domain/crypto/sessions/service/actions.dart';
import 'package:syphon/domain/hooks.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/actions.dart';
import 'package:syphon/domain/settings/devices-settings/selectors.dart';
import 'package:syphon/domain/settings/privacy-settings/actions.dart';
import 'package:syphon/domain/settings/privacy-settings/selectors.dart';
import 'package:syphon/domain/settings/privacy-settings/storage.dart';
import 'package:syphon/domain/settings/selectors.dart';
import 'package:syphon/domain/settings/storage-settings/actions.dart';
import 'package:syphon/domain/settings/theme-settings/selectors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/syphon.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm-password.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/dialogs/dialog-rounded.dart';
import 'package:syphon/views/widgets/dialogs/dialog-text-input.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/show-lock-overlay.dart';

class PrivacySettingsScreen extends HookWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // global actions dispatch

    final size = useDimensions(context);
    final width = size.width;

    final dispatch = useDispatch<AppState>();

    final bool isValid = useSelector<AppState, bool>(
      (state) =>
          state.authStore.credential != null &&
          state.authStore.credential!.value != null &&
          state.authStore.credential!.value!.isNotEmpty,
      fallback: false,
    )!;

    final bool loading = useSelector<AppState, bool>(
      (state) => state.authStore.loading,
      fallback: false,
    )!;

    final bool typingIndicators = useSelector<AppState, bool>(
      (state) => state.settingsStore.typingIndicatorsEnabled,
      fallback: false,
    )!;

    final bool screenLockEnabled = useSelector<AppState, bool>(
      (state) => selectScreenLockEnabled(Syphon.getAppContext(context)),
      fallback: false,
    )!;

    final String sessionId = useSelector<AppState, String?>(
      (state) => state.authStore.user.deviceId,
      fallback: Values.empty,
    )!;
    final String sessionName = useSelector<AppState, String>(
      (state) => selectCurrentDeviceName(state),
      fallback: Values.empty,
    )!;
    final String sessionKey = useSelector<AppState, String>(
      (state) => selectCurrentUserSessionKey(state),
      fallback: Values.empty,
    )!;

    final String keyBackupLatest = useSelector<AppState, String>(
      (state) => state.settingsStore.privacySettings.lastBackupMillis,
      fallback: Values.empty,
    )!;

    final String keyBackupSchedule = useSelector<AppState, String>(
      (state) => selectKeyBackupSchedule(state),
      fallback: Values.empty,
    )!;

    final String keyBackupLocation = useSelector<AppState, String>(
      (state) => selectKeyBackupLocation(state),
      fallback: Values.empty,
    )!;

    final String readReceipts = useSelector<AppState, String>(
      (state) => selectReadReceiptsString(state.settingsStore.readReceipts),
      fallback: Values.empty,
    )!;

    onResetConfirmAuth() => dispatch(resetInteractiveAuth());
    onIncrementReadReceipts() => dispatch(incrementReadReceipts());
    onToggleTypingIndicators() => dispatch(toggleTypingIndicators());

    onSetScreenLock(String matchedPin) async => dispatch(setScreenLock(pin: matchedPin));
    onRemoveScreenLock(String matchedPin) async => dispatch(removeScreenLock(pin: matchedPin));

    onCopyToClipboard(String? clipboardData) async {
      await Clipboard.setData(ClipboardData(text: clipboardData ?? ''));
      dispatch(addInfo(message: Strings.alertCopiedToClipboard));
      HapticFeedback.vibrate();
    }

    onRenameDevice() async {
      showDialog(
        context: context,
        builder: (dialogContext) => DialogTextInput(
          title: Strings.titleRenameDevice,
          content: Strings.contentRenameDevice,
          randomizeText: true,
          label: sessionName,
          onConfirm: (String newDisplayName) async {
            dispatch(
              renameDevice(
                deviceId: sessionId,
                displayName: newDisplayName,
              ),
            );
            Navigator.of(dialogContext).pop();
          },
          onCancel: () async {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    onDeactivateAccount() async {
      final store = StoreProvider.of<AppState>(context);

      // Attempt to deactivate account
      await store.dispatch(deactivateAccount());

      // Prompt for password if an Interactive Auth sessions was started
      final authSession = store.state.authStore.authSession;
      if (authSession != null) {
        showDialog(
          context: context,
          builder: (dialogContext) => DialogConfirmPassword(
            title: Strings.titleConfirmPassword,
            content: Strings.confirmDeactivate,
            checkLoading: () => store.state.settingsStore.loading,
            checkValid: () => isValid,
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
    }

    onConfirmDeactivateAccountFinal() async {
      await showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: Strings.titleDialogConfirmDeactivateAccountFinal,
          content: Strings.warrningDeactivateAccountFinal,
          loading: loading,
          confirmText: Strings.buttonDeactivate.capitalize(),
          confirmStyle: TextStyle(color: Colors.red),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            Navigator.of(dialogContext).pop();
            await onDeactivateAccount();
          },
        ),
      );
    }

    onConfirmDeactivateAccount() async {
      await showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: Strings.titleDialogConfirmDeactivateAccount,
          content: Strings.warningDeactivateAccount,
          confirmText: Strings.buttonDeactivate.capitalize(),
          confirmStyle: TextStyle(color: Colors.red),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            Navigator.of(dialogContext).pop();
            onResetConfirmAuth();
            onConfirmDeactivateAccountFinal();
          },
        ),
      );
    }

    onImportSessionKeys(BuildContext context) async {
      final store = StoreProvider.of<AppState>(context);

      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (file == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogTextInput(
          title: Strings.titleImportSessionKeys,
          content: Strings.contentImportSessionKeys,
          label: Strings.labelPassword,
          initialValue: '',
          confirmText: Strings.buttonTextImport,
          obscureText: true,
          loading: store.state.settingsStore.loading,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          onCancel: () async {
            Navigator.of(dialogContext).pop();
          },
          onConfirm: (String password) async {
            await store.dispatch(importSessionKeys(file, password: password));

            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    onUpdateBackupLocation() async {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Directory',
        initialDirectory: keyBackupLocation,
      );

      if (selectedDirectory == null) {
        dispatch(addInfo(message: 'No directory was selected'));
      } else {
        dispatch(SetKeyBackupLocation(
          location: selectedDirectory,
        ));
      }
    }

    onUpdateBackupSchedulePassword({
      required BuildContext context,
      required Function onComplete,
    }) async {
      final store = StoreProvider.of<AppState>(context);

      final password = await loadBackupPassword();

      if (password.isNotEmpty) {
        return onComplete();
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogTextInput(
          title: 'Scheduled Backup Password',
          content: Strings.contentExportSessionKeysEnterPassword,
          obscureText: true,
          loading: store.state.settingsStore.loading,
          label: Strings.labelPassword,
          initialValue: '',
          confirmText: Strings.buttonSave,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          onCancel: () async {
            Navigator.of(dialogContext).pop();
          },
          onConfirm: (String password) async {
            await store.dispatch(SetKeyBackupPassword(
              password: password,
            ));

            Navigator.of(dialogContext).pop();
            onComplete();
          },
        ),
      );
    }

    onUpdateBackupScheduleNotice({
      required BuildContext context,
      bool isDefault = false,
    }) async {
      final store = StoreProvider.of<AppState>(context);
      if (isDefault && Platform.isIOS) {
        await showDialog(
          context: context,
          builder: (dialogContext) => DialogConfirm(
            title: Strings.titleDialogKeyBackupWarning,
            content: Strings.contentKeyBackupWarning,
            confirmText: Strings.buttonConfirm,
            confirmStyle: TextStyle(color: Theme.of(context).primaryColor),
            dismissText: Strings.buttonCancel,
            onDismiss: () {
              store.dispatch(SetKeyBackupInterval(
                duration: Duration.zero,
              ));
              Navigator.pop(dialogContext);
            },
            onConfirm: () {
              Navigator.pop(dialogContext);
            },
          ),
        );
      }
    }

    onUpdateBackupSchedule({
      required BuildContext context,
    }) async {
      final store = StoreProvider.of<AppState>(context);
      final defaultPadding = EdgeInsets.symmetric(horizontal: 10);
      final isDefault = store.state.settingsStore.privacySettings.keyBackupInterval == Duration.zero;

      final onSelect = (BuildContext dialogContext, Duration duration) {
        store.dispatch(
          SetKeyBackupInterval(duration: duration),
        );
        Navigator.pop(dialogContext);
        onUpdateBackupScheduleNotice(
          context: context,
          isDefault: isDefault,
        );

        if (isDefault) {
          store.dispatch(startKeyBackupService());
        }
      };

      onUpdateBackupSchedulePassword(
        context: context,
        onComplete: () async => showDialog(
          context: context,
          builder: (dialogContext) => DialogRounded(
            title: 'Set Key Backup Schedule',
            children: [
              ListTile(
                title: Padding(
                    padding: defaultPadding,
                    child: Text(
                      'Manual Only',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                onTap: () {
                  onSelect(dialogContext, Duration.zero);
                },
              ),
              ListTile(
                title: Padding(
                    padding: defaultPadding,
                    child: Text(
                      'Every 15 Minutes',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                onTap: () {
                  onSelect(dialogContext, Duration(minutes: 15));
                },
              ),
              ListTile(
                title: Padding(
                    padding: defaultPadding,
                    child: Text(
                      'Every hour',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                onTap: () {
                  onSelect(dialogContext, Duration(hours: 1));
                },
              ),
              ListTile(
                title: Padding(
                    padding: defaultPadding,
                    child: Text(
                      'Every 6 hours',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                onTap: () {
                  onSelect(dialogContext, Duration(hours: 6));
                },
              ),
              ListTile(
                title: Padding(
                  padding: defaultPadding,
                  child: Text(
                    'Every 12 hours',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                onTap: () {
                  onSelect(dialogContext, Duration(hours: 12));
                },
              ),
              ListTile(
                title: Padding(
                  padding: defaultPadding,
                  child: Text(
                    'Every day',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                onTap: () {
                  onSelect(dialogContext, Duration(hours: 24));
                },
              ),
              ListTile(
                title: Padding(
                  padding: defaultPadding,
                  child: Text(
                    'Every week',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                onTap: () {
                  onSelect(dialogContext, Duration(days: 7));
                },
              ),
              ListTile(
                title: Padding(
                  padding: defaultPadding,
                  child: Text(
                    'Once a month',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                onTap: () {
                  onSelect(dialogContext, Duration(days: 29));
                },
              )
            ],
          ),
        ),
      );
    }

    onExportSessionKeys() async {
      final store = StoreProvider.of<AppState>(context);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogTextInput(
          title: Strings.titleDialogBackupSessionKeys,
          content: Strings.contentExportSessionKeys,
          obscureText: true,
          loading: store.state.settingsStore.loading,
          label: Strings.labelPassword,
          initialValue: '',
          confirmText: Strings.buttonSave,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          onCancel: () async {
            Navigator.of(dialogContext).pop();
          },
          onConfirm: (String password) async {
            await store.dispatch(exportSessionKeys(password));

            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    onDeleteSessionKeys() async {
      final store = StoreProvider.of<AppState>(context);
      await showDialog(
        context: context,
        builder: (dialogContext) => DialogConfirm(
          title: Strings.titleConfirmDeleteKeys,
          content: Strings.confirmDeleteKeys,
          loading: loading,
          confirmText: Strings.buttonTextConfirmDeleteKeys,
          confirmStyle: TextStyle(color: Colors.red),
          onDismiss: () => Navigator.pop(dialogContext),
          onConfirm: () async {
            await store.dispatch(resetSessionKeys());

            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }

    onSetScreenLockPin() {
      if (screenLockEnabled) {
        return showDialog(
          context: context,
          builder: (dialogContext) => DialogConfirm(
            title: Strings.titleDialogRemoveScreenLock,
            content: Strings.contentRemoveScreenLock,
            loading: loading,
            confirmText: Strings.buttonTextRemove,
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
                title: Text(Strings.titleDialogEnterScreenLockPin),
                onVerify: (String answer) async {
                  return true;
                },
                onConfirmed: (String matchedText) async {
                  await onRemoveScreenLock(matchedText);
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
        title: Text(Strings.titleDialogEnterNewScreenLockPin),
        confirmTitle: Text(Strings.titleDialogVerifyNewScreenLockPin),
        onVerify: (String answer) async {
          return true;
        },
        onConfirmed: (String matchedText) async {
          await onSetScreenLock(matchedText);
          Syphon.reloadCurrentContext(context);
          Navigator.of(context).pop();
        },
      );
    }

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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ListTile(
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Public Device Name',
                      ),
                      subtitle: Text(
                        sessionName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => onRenameDevice(),
                      trailing: IconButton(
                        onPressed: () => onRenameDevice(),
                        icon: Icon(Icons.edit),
                      ),
                    ),
                    ListTile(
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Session ID',
                      ),
                      subtitle: Text(
                        sessionId,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () async {
                        await onCopyToClipboard(sessionId);
                      },
                      trailing: IconButton(
                        onPressed: () => onCopyToClipboard(sessionId),
                        icon: Icon(Icons.copy),
                      ),
                    ),
                    ListTile(
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Session Key',
                      ),
                      subtitle: Text(
                        sessionKey,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () async {
                        await onCopyToClipboard(sessionKey);
                      },
                      trailing: IconButton(
                        onPressed: () => onCopyToClipboard(sessionKey),
                        icon: Icon(Icons.copy),
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
                        style: Theme.of(context).textTheme.titleSmall,
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
                        style: Theme.of(context).textTheme.bodySmall,
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
                        style: Theme.of(context).textTheme.bodySmall,
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ListTile(
                      onTap: () => onIncrementReadReceipts(),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        Strings.listItemSettingsReadReceipts,
                      ),
                      subtitle: Text(
                        Strings.subtitleSettingsReadReceipts,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Text(readReceipts),
                    ),
                    ListTile(
                      onTap: () => onToggleTypingIndicators(),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Typing Indicators',
                      ),
                      subtitle: Text(
                        'If typing indicators are disabled, you won\'t be able to see typing indicators from others',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Switch(
                        value: typingIndicators,
                        onChanged: (enterSend) => onToggleTypingIndicators(),
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ListTile(
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Screen lock',
                      ),
                      subtitle: Text(
                        'Lock ${Values.appName} access with native device screen lock or fingerprint',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Switch(
                        value: screenLockEnabled,
                        onChanged: (enabled) => onSetScreenLockPin(),
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
                        style: Theme.of(context).textTheme.bodySmall,
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    ListTile(
                      onTap: () => onImportSessionKeys(context),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Import Keys',
                      ),
                    ),
                    ListTile(
                      onTap: () => onExportSessionKeys(),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Backup Keys',
                      ),
                    ),
                    Visibility(
                      visible: true,
                      child: ListTile(
                        onTap: () => onUpdateBackupLocation(),
                        contentPadding: Dimensions.listPadding,
                        title: Text(
                          'Backup Folder',
                        ),
                        subtitle: Text(
                          keyBackupLocation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: true,
                      child: ListTile(
                        onTap: () => onUpdateBackupSchedule(context: context),
                        contentPadding: Dimensions.listPadding,
                        title: Text(
                          'Backup Schedule',
                        ),
                        subtitle: Text(
                          keyBackupSchedule,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          formatTimestampFull(
                            showTime: true,
                            lastUpdateMillis: int.parse(keyBackupLatest),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ListTile(
                      onTap: () => onDeleteSessionKeys(),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Delete Keys',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () => onConfirmDeactivateAccount(),
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
  }
}

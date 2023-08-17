import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/domain/alerts/actions.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/domain/auth/selectors.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/actions.dart';
import 'package:syphon/domain/settings/selectors.dart';
import 'package:syphon/domain/settings/theme-settings/selectors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/syphon.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/modals/modal-context-switcher.dart';

import 'widgets/profile-preview.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  onToggleAccountBottomSheet(BuildContext context, _Props props) {
    if (props.accountLoading) {
      return props.onAddInfo(Strings.alertWaitForFullSync);
    }

    if (props.accountsAvailable == 0) {
      return props.onAddInfo(Strings.alertLogOutToEnableMultiaccounts);
    }

    // NOTE: example of setting modal backgroound w/ inkwell working
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: Dimensions.modalBorderRadius,
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      builder: (contextModal) => ModalContextSwitcher(),
    );
  }

  onLogout(BuildContext context, _Props props) {
    var content = Strings.contentLogoutConfirm;

    if (props.accountsAvailable > 1) {
      content += Strings.contentLogoutMultiaccountConfirm;
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DialogConfirm(
        title: Strings.titleDialogLogout,
        content: content,
        onConfirm: () async {
          await props.onLogoutUser();
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  // Preloads owned devices before viewing current device
  onNavigatePrivacySettings(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);

    store.dispatch(fetchDevices());
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(
            store,
            Syphon.getAppContext(context),
          ),
      builder: (context, props) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: Strings.labelBack,
                onPressed: props.authLoading ? null : () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleSettings,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: SingleChildScrollView(
              physics: props.authLoading ? const NeverScrollableScrollPhysics() : null,
              // Use a container of the same height and width
              // to flex dynamically but within a single child scroll
              child: IgnorePointer(
                ignoring: props.authLoading,
                child: Column(
                  children: <Widget>[
                    InkWell(
                      onTap: props.authLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, Routes.settingsProfile);
                            },
                      child: Container(
                        padding: Dimensions.heroPadding,
                        child: ProfilePreview(
                          hasMultiaccounts: false,
                          onModifyAccounts: () => onToggleAccountBottomSheet(context, props),
                        ),
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => props.onDisabled(),
                          child: ListTile(
                            contentPadding: Dimensions.listPaddingSettings,
                            enabled: false,
                            title: Text(
                              Strings.listItemSettingsSms,
                            ),
                            subtitle: Text(
                              Strings.labelOff,
                              style: const TextStyle(fontSize: 14.0),
                            ),
                            leading: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.chat,
                                  size: 28,
                                )),
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.settingsNotifications);
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.notifications,
                                size: 28,
                              )),
                          title: Text(
                            Strings.listItemSettingsNotification,
                          ),
                          subtitle: Text(
                            props.notificationsEnabled! ? Strings.labelOn : Strings.labelOff,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                        GestureDetector(
                          onTapDown: (details) => onNavigatePrivacySettings(context),
                          child: ListTile(
                            enabled: !props.authLoading,
                            onTap: () {
                              Navigator.pushNamed(context, Routes.settingsPrivacy);
                            },
                            contentPadding: Dimensions.listPaddingSettings,
                            leading: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.lock,
                                  size: 28,
                                )),
                            title: Text(
                              Strings.titlePrivacy,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              Strings.subtitlePrivacySettings(
                                  props.screenLockEnabled ?? false ? Strings.labelOn : Strings.labelOff,
                                  Strings.labelOff //TODO
                                  ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.settingsTheme);
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.brightness_medium,
                                size: 28,
                              )),
                          title: Text(
                            Strings.titleTheming,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            Strings.subtitleThemeSettings(props.themeTypeName, props.fontName),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.settingsChat);
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: const EdgeInsets.only(
                                top: 4,
                                left: 4,
                                bottom: 4,
                                right: 4,
                              ),
                              child: const Icon(
                                Icons.photo_filter,
                                size: 28,
                              )),
                          title: Text(
                            Strings.titleChatSettings,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.settingsDevices);
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.phone_android,
                                size: 28,
                              )),
                          title: Text(
                            Strings.titleDevices,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.settingsAdvanced);
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.code,
                                size: 28,
                              )),
                          title: Text(
                            Strings.titleAdvanced,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () => props.onLogoutUser(),
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.exit_to_app,
                                size: 28,
                              )),
                          title: Text(
                            Strings.listItemSettingsLogout,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Visibility(
                            visible: props.authLoading,
                            child: Container(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.secondary,
                                ),
                                value: null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ));
}

class _Props extends Equatable {
  final bool loading;
  final bool authLoading;
  final bool accountLoading;
  final bool? screenLockEnabled;
  final int accountsAvailable;
  final bool? notificationsEnabled;
  final String? fontName;
  final String themeTypeName;

  final Function onAddInfo;
  final Function onDisabled;
  final Function onLogoutUser;

  const _Props({
    required this.fontName,
    required this.themeTypeName,
    required this.loading,
    required this.authLoading,
    required this.accountLoading,
    required this.accountsAvailable,
    required this.notificationsEnabled,
    required this.screenLockEnabled,
    required this.onAddInfo,
    required this.onDisabled,
    required this.onLogoutUser,
  });

  @override
  List<Object?> get props => [
        themeTypeName,
        loading,
        authLoading,
        notificationsEnabled,
        accountLoading,
      ];

  static _Props mapStateToProps(Store<AppState> store, AppContext context) => _Props(
        accountLoading: !store.state.cryptoStore.oneTimeKeysStable ||
            !store.state.syncStore.synced ||
            store.state.syncStore.lastSince == null,
        screenLockEnabled: selectScreenLockEnabled(context),
        accountsAvailable: selectAvailableAccounts(store.state),
        fontName: selectFontNameString(store.state.settingsStore.themeSettings.fontName),
        themeTypeName: selectThemeTypeString(store.state.settingsStore.themeSettings.themeType),
        loading: store.state.roomStore.loading,
        authLoading: store.state.authStore.loading,
        notificationsEnabled: store.state.settingsStore.notificationSettings.enabled,
        onDisabled: () => store.dispatch(addInProgress()),
        onLogoutUser: () => store.dispatch(logoutUser()),
        onAddInfo: (message) {
          store.dispatch(addInfo(origin: 'ModalContextSwitcher', message: message));
        },
      );
}

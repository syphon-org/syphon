import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/modals/modal-context-switcher.dart';
import 'widgets/profile-preview.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  onToggleAccountBottomSheet(BuildContext context, _Props props) {
    if (props.accountLoading) {
      return props.onAddInfo('Wait for full sync to finish before switching accounts');
    }

    // NOTE: example of setting modal backgroound w/ inkwell working
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: Dimensions.modalBorderRadius,
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      builder: (contextModal) => ModalContextSwitcher(),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: props.authLoading ? null : () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleSettings,
                style: TextStyle(
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
                              Navigator.pushNamed(context, '/profile');
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
                              tr('list-item-settings-sms'),
                            ),
                            subtitle: Text(
                              Strings.labelOff, // TODO: add SMS feature
                              style: TextStyle(fontSize: 14.0),
                            ),
                            leading: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.chat,
                                  size: 28,
                                )),
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/notifications',
                            );
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.notifications,
                                size: 28,
                              )),
                          title: Text(
                            tr('list-item-settings-notification'),
                          ),
                          subtitle: Text(
                            props.notificationsEnabled! ? Strings.labelOn : Strings.labelOff,
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, '/privacy');
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.lock,
                                size: 28,
                              )),
                          title: Text(
                            tr('list-item-settings-privacy'),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          subtitle: Text(
                            'Screen Lock Off, Registration Lock Off',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, NavigationPaths.theming);
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.brightness_medium,
                                size: 28,
                              )),
                          title: Text(
                            tr('title-view-theming'),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          subtitle: Text(
                            'Theme ${props.themeTypeName}, Font ${props.fontName}',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, '/chat-preferences');
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.only(
                                top: 4,
                                left: 4,
                                bottom: 4,
                                right: 4,
                              ),
                              child: Icon(
                                Icons.photo_filter,
                                size: 28,
                              )),
                          title: Text(
                            tr('list-item-settings-chat'),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, '/devices');
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.phone_android,
                                size: 28,
                              )),
                          title: Text(
                            tr('title-view-devices'),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () {
                            Navigator.pushNamed(context, '/advanced');
                          },
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.code,
                                size: 28,
                              )),
                          title: Text(
                            tr('title-view-advanced'),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        ListTile(
                          enabled: !props.authLoading,
                          onTap: () => props.onLogoutUser(),
                          contentPadding: Dimensions.listPaddingSettings,
                          leading: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.exit_to_app,
                                size: 28,
                              )),
                          title: Text(
                            tr('list-item-settings-logout'),
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Visibility(
                            visible: props.authLoading,
                            child: Container(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor,
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
  final bool hasMultiaccounts;
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
    required this.hasMultiaccounts,
    required this.notificationsEnabled,
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

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        accountLoading: !store.state.cryptoStore.oneTimeKeysStable ||
            !store.state.syncStore.synced ||
            store.state.syncStore.lastSince == null,
        hasMultiaccounts: selectHasMultiaccount(store.state),
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

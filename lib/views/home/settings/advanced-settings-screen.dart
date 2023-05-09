import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/crypto/keys/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/service/actions.dart';
import 'package:syphon/store/sync/service/service.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/dialogs/dialog-text-input.dart';

class _Props extends Equatable {
  final bool syncing;
  final bool syncObserverActive;
  final bool checkForUpdates;
  final String? language;
  final String? lastSince;
  final User currentUser;
  final int syncInterval;

  final Function onToggleSyncing;
  final Function onToggleCheckUpdates;
  final Function onManualSync;
  final Function onForceFullSync;
  final Function onForceFunction;
  final Function onStartBackgroundSync;
  final Function onEditSyncInterval;

  const _Props({
    required this.syncing,
    required this.checkForUpdates,
    required this.language,
    required this.syncObserverActive,
    required this.currentUser,
    required this.lastSince,
    required this.syncInterval,
    required this.onManualSync,
    required this.onForceFullSync,
    required this.onToggleSyncing,
    required this.onToggleCheckUpdates,
    required this.onForceFunction,
    required this.onStartBackgroundSync,
    required this.onEditSyncInterval,
  });

  @override
  List<Object?> get props => [
        syncing,
        syncInterval,
        checkForUpdates,
        lastSince,
        currentUser,
        syncObserverActive,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        syncing: store.state.syncStore.syncing,
        checkForUpdates: store.state.settingsStore.checkForUpdatesEnabled,
        language: store.state.settingsStore.language,
        currentUser: store.state.authStore.user,
        lastSince: store.state.syncStore.lastSince,
        syncInterval: store.state.settingsStore.syncInterval,
        syncObserverActive: store.state.syncStore.syncObserver != null &&
            store.state.syncStore.syncObserver!.isActive,
        onEditSyncInterval: (BuildContext context) {
          return showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DialogTextInput(
              title: Strings.titleDialogSyncInterval,
              content: Strings.confirmModifySyncInterval,
              editingController: TextEditingController(
                text: Duration(
                  milliseconds: store.state.settingsStore.syncInterval,
                ).inSeconds.toString(),
              ),
              label: Strings.labelSeconds,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                FilteringTextInputFormatter.singleLineFormatter
              ],
              onCancel: () {
                Navigator.of(dialogContext).pop();
              },
              onConfirm: (String interval) async {
                store.dispatch(SetSyncInterval(
                    syncInterval: Duration(
                  seconds: int.parse(interval),
                ).inMilliseconds));

                await store.dispatch(stopSyncObserver());
                await store.dispatch(startSyncObserver());
                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
        onToggleSyncing: () {
          final observer = store.state.syncStore.syncObserver;
          if (observer != null && observer.isActive) {
            store.dispatch(stopSyncObserver());
          } else {
            store.dispatch(startSyncObserver());
          }
        },
        onToggleCheckUpdates: () {
          store.dispatch(toggleCheckForUpdates());
        },
        onStartBackgroundSync: () async {
          store.dispatch(startSyncService());
        },
        onManualSync: () {
          store.dispatch(fetchSync(since: store.state.syncStore.lastSince));
        },
        onForceFullSync: () {
          store.dispatch(fetchSync(forceFull: true));
        },
        onForceFunction: () {
          store.dispatch(generateOneTimeKeys());
        },
      );
}

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({Key? key}) : super(key: key);

  @override
  AdvancedSettingsScreenState createState() => AdvancedSettingsScreenState();
}

class AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  AdvancedSettingsScreenState();

  String? version;
  String? buildNumber;

  @override
  void initState() {
    super.initState();
    onMounted();
  }

  Future onMounted() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          return Scaffold(
            appBar: AppBarNormal(
              title: Strings.titleAdvanced,
            ),
            body: SingleChildScrollView(
                child: Column(
              children: <Widget>[
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    onTap: () => props.onStartBackgroundSync(),
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      Strings.listItemAdvancedSettingsStartBackground,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    onTap: () {
                      SyncService.stop();
                      dismissAllNotifications(
                        pluginInstance: globalNotificationPluginInstance,
                      );
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      Strings.listItemAdvancedSettingsStopBackground,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    onTap: () {
                      showMessageNotificationTest(
                        pluginInstance: globalNotificationPluginInstance!,
                      );
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                        Strings.listItemAdvancedSettingsTestNotifications,
                        style: Theme.of(context).textTheme.subtitle1),
                  ),
                ),
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    onTap: () async {
                      await notificationSyncTEST();
                    },
                    contentPadding: Dimensions.listPadding,
                    title: Text(Strings.listItemAdvancedSettingsTestSyncLoop,
                        style: Theme.of(context).textTheme.subtitle1),
                  ),
                ),
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    contentPadding: Dimensions.listPadding,
                    onTap: () {
                      props.onForceFunction();
                    },
                    title: Text(Strings.listItemAdvancedSettingsForceFunction,
                        style: Theme.of(context).textTheme.subtitle1),
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Navigator.pushNamed(context, Routes.licenses);
                  },
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemAdvancedSettingsLicenses,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Navigator.pushNamed(context, Routes.settingsProxy);
                  },
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemSettingsProxy,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () => props.onEditSyncInterval(context),
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemSettingsSyncInterval,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  subtitle: Text(
                    Strings.subtitleSettingsSyncInterval,
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      Duration(milliseconds: props.syncInterval)
                          .inSeconds
                          .toString(),
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: props.onToggleSyncing as void Function()?,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemSettingsSyncToggle,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  subtitle: Text(
                    Strings.subtitleSettingsSyncToggle,
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      props.syncObserverActive
                          ? Strings.labelSyncing
                          : Strings.labelStopped,
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Opacity(
                  opacity: props.syncing ? 0.5 : 1,
                  child: ListTile(
                    dense: true,
                    onTap: props.syncing
                        ? null
                        : props.onManualSync as void Function()?,
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      Strings.listItemSettingsManualSync,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: props.syncing
                                ? Color(AppColors.greyDisabled)
                                : null,
                          ),
                    ),
                    subtitle: Text(
                      Strings.subtitleManualSync,
                      style: TextStyle(
                        color: props.syncing
                            ? Color(AppColors.greyDisabled)
                            : null,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(
                          value: props.syncing ? null : 0),
                    ),
                  ),
                ),
                Opacity(
                  opacity: props.syncing ? 0.5 : 1,
                  child: ListTile(
                    dense: true,
                    onTap: props.syncing
                        ? null
                        : props.onForceFullSync as void Function()?,
                    contentPadding: Dimensions.listPadding,
                    title: Text(
                      Strings.listItemSettingsForceFullSync,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: props.syncing
                                ? Color(AppColors.greyDisabled)
                                : null,
                          ),
                    ),
                    subtitle: Text(
                      Strings.subtitleForceFullSync,
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(
                        value: props.syncing ? null : 0,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  onTap: () => props.onToggleCheckUpdates(),
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemAdvancedSettingsCheckForUpdates,
                  ),
                  subtitle: Text(
                    Strings.listItemAdvancedSettingsCheckForUpdatesBody,
                    style: Theme.of(context).textTheme.caption,
                  ),
                  trailing: Switch(
                    value: props.checkForUpdates,
                    onChanged: (check) => props.onToggleCheckUpdates(),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.labelVersion,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  trailing: Text(
                    '$version ($buildNumber)',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            )),
          );
        },
      );
}

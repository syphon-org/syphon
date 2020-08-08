// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm-password.dart';

final String debug = DotEnv().env['DEBUG'];

class DevicesView extends StatefulWidget {
  @override
  DeviceViewState createState() => DeviceViewState();
}

class DeviceViewState extends State<DevicesView> {
  DeviceViewState({Key key}) : super();

  List<Device> selectedDevices;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  onDismissDeviceOptions() {
    this.setState(() {
      selectedDevices = null;
    });
  }

  @protected
  onToggleAllDevices({List<Device> devices}) {
    var newSelectedDevices = this.selectedDevices ?? List<Device>();

    if (newSelectedDevices.length == devices.length) {
      newSelectedDevices = [];
    } else {
      newSelectedDevices = devices;
    }

    this.setState(() {
      selectedDevices = newSelectedDevices;
    });
  }

  @protected
  onToggleModifyDevice({Device device}) {
    var newSelectedDevices = this.selectedDevices ?? List<Device>();

    if (newSelectedDevices.contains(device)) {
      newSelectedDevices.remove(device);
    } else {
      newSelectedDevices.add(device);
    }

    this.setState(() {
      selectedDevices = newSelectedDevices;
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    store.dispatch(fetchDevices());
    store.dispatch(fetchNotificationPushers());
  }

  @protected
  Widget buildDeviceOptionsBar({BuildContext context, Props props}) {
    var selfSelectedDevice;

    if (this.selectedDevices != null) {
      selfSelectedDevice = this.selectedDevices.indexWhere(
            (device) => device.deviceId == props.currentDeviceId,
          );
    }

    return AppBar(
      brightness: Brightness.dark, // TOOD: this should inherit from theme
      backgroundColor: Colors.grey[500],
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.close),
              color: Colors.white,
              iconSize: Dimensions.buttonAppBarSize,
              onPressed: onDismissDeviceOptions,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.text_fields),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'TEST KEY FUNCTION GENERIC',
          color: Colors.white,
          onPressed: () {
            props.onTest();
          },
        ),
        IconButton(
          icon: Icon(Icons.edit),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'Rename Device',
          color: Colors.white,
          onPressed: this.selectedDevices.length != 1 ? null : () {},
        ),
        IconButton(
          icon: Icon(Icons.delete),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'Delete Device',
          color: Colors.white,
          onPressed: selfSelectedDevice != -1
              ? null
              : () => props.onDeleteDevices(
                    context,
                    this.selectedDevices,
                    onComplete: () {},
                  ),
        ),
        IconButton(
          icon: Icon(Icons.select_all),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'Select All',
          color: Colors.white,
          onPressed: () => onToggleAllDevices(devices: props.devices),
        ),
      ],
    );
  }

  @protected
  Widget buildAppBar({BuildContext context, Props props}) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context, false),
      ),
      title: Text(
        Strings.titleViewDevices,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          final sectionBackgroundColor =
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(Colours.blackDefault)
                  : const Color(Colours.whiteDefault);

          var currentAppBar = buildAppBar(
            props: props,
            context: context,
          );

          if (this.selectedDevices != null) {
            currentAppBar = buildDeviceOptionsBar(
              props: props,
              context: context,
            );
          }

          return Scaffold(
            appBar: currentAppBar,
            body: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Stack(
                children: [
                  GridView.builder(
                    primary: true,
                    shrinkWrap: true,
                    itemCount: props.devices.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final device = props.devices[index];

                      Color iconColor;
                      Color backgroundColor;
                      IconData deviceTypeIcon = Icons.phone_android;
                      TextStyle textStyle = Theme.of(context)
                          .textTheme
                          .caption
                          .copyWith(fontSize: 12);
                      bool isCurrentDevice =
                          props.currentDeviceId == device.deviceId;

                      if (device.displayName.contains('Firefox') ||
                          device.displayName.contains('Mac')) {
                        deviceTypeIcon = Icons.laptop;
                      } else if (device.displayName.contains('iOS')) {
                        deviceTypeIcon = Icons.phone_iphone;
                      }

                      if (this.selectedDevices != null &&
                          this.selectedDevices.contains(device)) {
                        backgroundColor = Colours.hashedColor(device.deviceId);
                        backgroundColor = Colors.grey[500];
                        textStyle = textStyle.copyWith(color: Colors.white);
                        iconColor = Colors.white;
                      }

                      return InkWell(
                        onTap: this.selectedDevices == null
                            ? null
                            : () => onToggleModifyDevice(device: device),
                        onLongPress: () => onToggleModifyDevice(device: device),
                        child: Card(
                          elevation: 0,
                          color: backgroundColor ?? sectionBackgroundColor,
                          child: Container(
                            // padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Stack(
                                  children: <Widget>[
                                    Container(
                                      padding:
                                          EdgeInsets.only(bottom: 8, top: 8),
                                      child: Icon(
                                        deviceTypeIcon,
                                        size: Dimensions.iconSize * 1.5,
                                        color: iconColor,
                                      ),
                                    ),
                                    Visibility(
                                      visible: isCurrentDevice,
                                      child: Positioned(
                                        right: 0,
                                        bottom: 4,
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.cyan,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      device.displayName,
                                      textAlign: TextAlign.center,
                                      style: textStyle,
                                    ),
                                    Text(
                                      device.deviceId,
                                      overflow: TextOverflow.ellipsis,
                                      style: textStyle,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    child: Visibility(
                      visible: props.loading,
                      child: Container(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          RefreshProgressIndicator(
                            strokeWidth: Dimensions.defaultStrokeWidth,
                            valueColor: new AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                            value: null,
                          ),
                        ],
                      )),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class Props extends Equatable {
  final bool loading;
  final String session;
  final List<Device> devices;
  final String currentDeviceId;

  final Function onFetchDevices;
  final Function onDeleteDevices;
  final Function onTest;

  Props({
    @required this.loading,
    @required this.devices,
    @required this.session,
    @required this.currentDeviceId,
    @required this.onFetchDevices,
    @required this.onDeleteDevices,
    @required this.onTest,
  });

  @override
  List<Object> get props => [
        loading,
        devices,
      ];

  static Props mapStateToProps(
    Store<AppState> store,
  ) =>
      Props(
        loading: store.state.settingsStore.loading,
        devices: store.state.settingsStore.devices ?? const [],
        session: store.state.authStore.session,
        currentDeviceId: store.state.authStore.user.deviceId,
        onTest: () {
          store.dispatch(fetchDeviceKeys());
        },
        onDeleteDevices: (
          BuildContext context,
          List<Device> devices, {
          Function onComplete,
        }) async {
          if (devices.isEmpty) return;

          final List<String> deviceIds =
              devices.map((device) => device.deviceId).toList();

          if (devices.length == 1) {
            await store.dispatch(deleteDevice(deviceId: deviceIds[0]));
          } else {
            await store.dispatch(deleteDevices(deviceIds: deviceIds));
          }
          final authSession = store.state.authStore.session;
          if (authSession != null) {
            showDialog(
              context: context,
              child: DialogConfirmPassword(
                key: Key(authSession),
                onConfirm: () async {
                  final List<String> deviceIds =
                      devices.map((device) => device.deviceId).toList();

                  if (devices.length == 1) {
                    await store.dispatch(deleteDevice(deviceId: deviceIds[0]));
                  } else {
                    await store.dispatch(deleteDevices(deviceIds: deviceIds));
                  }
                  store.dispatch(resetCredentials());
                  if (onComplete != null) {
                    onComplete();
                  }
                },
                onCancel: () async {
                  store.dispatch(resetCredentials());
                },
              ),
            );
          }
        },
        onFetchDevices: () {
          store.dispatch(fetchDevices());
        },
      );
}

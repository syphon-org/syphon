import 'dart:io';

import 'package:Tether/global/dimensions.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class DevicesView extends StatefulWidget {
  @override
  DeviceViewState createState() => DeviceViewState();
}

class DeviceViewState extends State<DevicesView> {
  DeviceViewState({Key key}) : super();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(fetchDevices());
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
        builder: (context, props) {
          final sectionBackgroundColor =
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(BASICALLY_BLACK)
                  : const Color(BACKGROUND);

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                StringStore.viewTitleDevices,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: Container(
              child: GridView.builder(
                primary: true,
                shrinkWrap: true,
                itemCount: props.devices.length,
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final device = props.devices[index];

                  var deviceTypeIcon = Icons.phone_android;

                  if (device.displayName.contains('Firefox') ||
                      device.displayName.contains('Mac')) {
                    deviceTypeIcon = Icons.laptop;
                  } else if (device.displayName.contains('iOS')) {
                    deviceTypeIcon = Icons.phone_iphone;
                  }
                  return Card(
                    color: sectionBackgroundColor,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            deviceTypeIcon,
                            size: Dimensions.iconSize,
                          ),
                          Text(
                            device.displayName,
                            style: Theme.of(context).textTheme.caption,
                          ),
                          Text(
                            device.deviceId,
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
}

class Props extends Equatable {
  final bool loading;
  final List<DeviceSetting> devices;

  final Function onFetchDevices;

  Props({
    @required this.loading,
    @required this.devices,
    @required this.onFetchDevices,
  });

  @override
  List<Object> get props => [
        loading,
        devices,
      ];

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
        loading: store.state.settingsStore.loading,
        devices: store.state.settingsStore.devices ?? const [],
        onFetchDevices: () {
          store.dispatch(fetchDevices());
        },
      );
}

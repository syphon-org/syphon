import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';

class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBarNormal(
              title: 'Storage',
            ),
            body: Column(
              children: <Widget>[
                Container(
                  width: width,
                  padding: Dimensions.listPadding,
                  child: Text(
                    'Backups',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    contentPadding: Dimensions.listPadding,
                    onTap: () {
                      props.onExportDeviceKey();
                    },
                    title: Text(
                      'Export Device Key',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                Visibility(
                  visible: DEBUG_MODE,
                  child: ListTile(
                    dense: true,
                    contentPadding: Dimensions.listPadding,
                    onTap: () {
                      props.onImportDeviceKey();
                    },
                    title: Text(
                      'Import Device Key',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final Function onExportDeviceKey;
  final Function onImportDeviceKey;

  const _Props({
    required this.onExportDeviceKey,
    required this.onImportDeviceKey,
  });

  @override
  List<Object> get props => [];

  static _Props mapStateToProps(
    Store<AppState> store,
  ) =>
      _Props(
        onExportDeviceKey: () {
          store.dispatch(exportDeviceKeysOwned());
        },
        onImportDeviceKey: () {
          store.dispatch(importDeviceKeysOwned());
        },
      );
}

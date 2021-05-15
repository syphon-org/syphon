// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';

final bool debug = !kReleaseMode;

class StorageView extends StatelessWidget {
  StorageView({Key? key}) : super(key: key);

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
                'Storage',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
              ),
            ),
            body: Container(
                child: Column(
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
                  maintainSize: false,
                  visible: !debug,
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
                  maintainSize: false,
                  visible: !debug,
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
            )),
          );
        },
      );
}

class _Props extends Equatable {
  final Function onExportDeviceKey;
  final Function onImportDeviceKey;

  _Props({
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

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];
final String protocol = DotEnv().env['PROTOCOL'];

class StorageView extends StatelessWidget {
  StorageView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

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
                  width: width, // TODO: use flex, i'm rushing
                  padding: Dimensions.listPadding,
                  child: Text(
                    'Backups',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
                Visibility(
                  maintainSize: false,
                  visible: debug == 'true',
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
                  visible: debug == 'true',
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
    @required this.onExportDeviceKey,
    @required this.onImportDeviceKey,
  });

  @override
  List<Object> get props => [];

  /* effectively mapStateToProps, but includes functions */
  static _Props mapStoreToProps(
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

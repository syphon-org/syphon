import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/crypto/actions.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

class PrivacyPreferences extends StatelessWidget {
  PrivacyPreferences({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

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
                title,
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
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: Dimensions.listPadding,
                              child: Text(
                                'App access',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              onTap: null,
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Screen lock',
                              ),
                              subtitle: Text(
                                'Lock Tether access with native device screen lock or fingerprint',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: false,
                                onChanged: null,
                              ),
                            ),
                            ListTile(
                              onTap: null,
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
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: Dimensions.listPadding,
                              child: Text(
                                'User Access',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              onTap: () {
                                Navigator.pushNamed(context, '/password');
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
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
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
                                value: props.readReceipts,
                                onChanged: (enterSend) =>
                                    props.onToggleReadReceipts(),
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
                                value: props.typingIndicators,
                                onChanged: (enterSend) =>
                                    props.onToggleTypingIndicators(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: Dimensions.listPadding,
                              child: Text(
                                'Encryption Keys',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              onTap: props.onImportDeviceKey,
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Import Keys',
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onExportDeviceKey(context),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Export Keys',
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
                    ),
                  ],
                )),
          );
        },
      );
}

class Props extends Equatable {
  final bool typingIndicators;
  final bool readReceipts;

  final Function onToggleTypingIndicators;
  final Function onToggleReadReceipts;
  final Function onExportDeviceKey;
  final Function onImportDeviceKey;
  final Function onDeleteDeviceKey;

  Props({
    @required this.typingIndicators,
    @required this.readReceipts,
    @required this.onToggleTypingIndicators,
    @required this.onToggleReadReceipts,
    @required this.onExportDeviceKey,
    @required this.onImportDeviceKey,
    @required this.onDeleteDeviceKey,
  });

  @override
  List<Object> get props => [
        typingIndicators,
        readReceipts,
      ];

  static Props mapStoreToProps(Store<AppState> store) => Props(
        typingIndicators: store.state.settingsStore.typingIndicators,
        readReceipts: store.state.settingsStore.readReceipts,
        onToggleTypingIndicators: () => store.dispatch(
          toggleTypingIndicators(),
        ),
        onToggleReadReceipts: () => store.dispatch(
          toggleReadReceipts(),
        ),
        onExportDeviceKey: (BuildContext context) async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Confirm Exporting Keys"),
              content: Text(Strings.contentDeleteDeviceKeyWarning),
              actions: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text(
                    'Export Keys',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onPressed: () async {
                    store.dispatch(exportDeviceKeysOwned());
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
        onImportDeviceKey: () {
          store.dispatch(importDeviceKeysOwned());
        },
        onDeleteDeviceKey: (BuildContext context) async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Confirm Deleting Keys"),
              content: Text(
                  "Are you sure you want to delete your encryption keys for this device?"),
              actions: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text(
                    'Delete Keys',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onPressed: () async {
                    await store.dispatch(deleteDeviceKeys());
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
}

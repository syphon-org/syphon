import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:Tether/global/colors.dart';
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

          // Static horizontal: 16, vertical: 8
          final contentPadding = EdgeInsets.only(
            left: width * 0.04,
            right: width * 0.04,
            top: 6,
            bottom: 14,
          );

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
              title: Text(title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w100)),
            ),
            body: Container(
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
                          padding: contentPadding,
                          child: Text(
                            'App access',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          onTap: null,
                          contentPadding: contentPadding,
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
                          contentPadding: contentPadding,
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
                          padding: contentPadding,
                          child: Text(
                            'Communication',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          onTap: () => props.onToggleReadReceipts(),
                          contentPadding: contentPadding,
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
                          contentPadding: contentPadding,
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
              ],
            )),
          );
        },
      );
}

class Props {
  final bool typingIndicators;
  final bool readReceipts;

  final Function onToggleTypingIndicators;
  final Function onToggleReadReceipts;

  Props({
    @required this.typingIndicators,
    @required this.readReceipts,
    @required this.onToggleTypingIndicators,
    @required this.onToggleReadReceipts,
  });

  static Props mapStoreToProps(Store<AppState> store) => Props(
        typingIndicators: store.state.settingsStore.typingIndicators,
        readReceipts: store.state.settingsStore.readReceipts,
        onToggleTypingIndicators: () => store.dispatch(
          toggleTypingIndicators(),
        ),
        onToggleReadReceipts: () => store.dispatch(
          toggleReadReceipts(),
        ),
      );

  @override
  int get hashCode =>
      typingIndicators.hashCode ^
      readReceipts.hashCode ^
      onToggleTypingIndicators.hashCode ^
      onToggleReadReceipts.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          typingIndicators == other.typingIndicators &&
          readReceipts == other.readReceipts &&
          onToggleTypingIndicators == other.onToggleTypingIndicators &&
          onToggleReadReceipts == other.onToggleReadReceipts;
}

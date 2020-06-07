import 'package:Tether/global/dimensions.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

class ChatPreferences extends StatelessWidget {
  ChatPreferences({Key key, this.title}) : super(key: key);

  final String title;

  displayThemeType(String themeTypeName) {
    return themeTypeName.split('.')[1].toLowerCase();
  }

  @protected
  onShowColorPicker({
    onSelectColor,
    context,
    int originalColor,
  }) async {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return await showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Primary Color'),
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.02,
          vertical: 12,
        ),
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              maxWidth: width * 0.8,
              maxHeight: height * 0.25,
            ),
            child: MaterialColorPicker(
              selectedColor: Colors.red,
              onColorChange: (Color color) {
                onSelectColor(color.value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SimpleDialogOption(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onPressed: () {
                  onSelectColor(null);
                  Navigator.pop(context);
                },
                child: Text(
                  'reset',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleDialogOption(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    onPressed: () {
                      onSelectColor(originalColor);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'cancel',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  SimpleDialogOption(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'save',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;

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
            body: SingleChildScrollView(
              child: Container(
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
                              'Chats',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Language',
                            ),
                            trailing: Text(
                              props.language,
                            ),
                          ),
                          ListTile(
                            onTap: () {},
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Message Font Size',
                            ),
                            trailing: Text(
                              props.chatFontSize,
                            ),
                          ),
                          ListTile(
                            onTap: () => props.onToggleEnterSend(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Show Membership Events',
                            ),
                            subtitle: Text(
                              'Show membership changes within the chat',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.enterSend,
                              onChanged: (enterSend) =>
                                  props.onToggleEnterSend(),
                            ),
                          ),
                          ListTile(
                            onTap: () => props.onToggleEnterSend(),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'Enter Key Sends',
                            ),
                            subtitle: Text(
                              'Pressing the enter key will send a message',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            trailing: Switch(
                              value: props.enterSend,
                              onChanged: (enterSend) =>
                                  props.onToggleEnterSend(),
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
                              'Media',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () => onShowColorPicker(
                              context: context,
                              onSelectColor: props.onSelectPrimaryColor,
                              originalColor: props.primaryColor,
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'View all uploaded Media',
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            subtitle: Text(
                              'See all uploaded data, even those unaccessible from messages',
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
                              'Media auto-download',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            onTap: () => onShowColorPicker(
                              context: context,
                              onSelectColor: props.onSelectPrimaryColor,
                              originalColor: props.primaryColor,
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'When using mobile data',
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            subtitle: Text(
                              'Images, Audio, Video, Documents, Other',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            onTap: () => onShowColorPicker(
                              context: context,
                              onSelectColor: props.onSelectPrimaryColor,
                              originalColor: props.primaryColor,
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'When using Wi-Fi',
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            subtitle: Text(
                              'Images, Audio, Video, Documents, Other',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          ListTile(
                            onTap: () => onShowColorPicker(
                              context: context,
                              onSelectColor: props.onSelectPrimaryColor,
                              originalColor: props.primaryColor,
                            ),
                            contentPadding: Dimensions.listPadding,
                            title: Text(
                              'When Roaming',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            subtitle: Text(
                              'Images, Audio, Video, Documents, Other',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
            ),
          );
        },
      );
}

class Props {
  final int primaryColor;
  final int accentColor;
  final String themeType;
  final String language;
  final String fontSize;
  final String chatFontSize;
  final bool enterSend;

  final Function onSelectPrimaryColor;
  final Function onSelectAccentColor;
  final Function onIncrementTheme;
  final Function onToggleEnterSend;
  final Function onToggleMembershipEvents;

  Props({
    @required this.primaryColor,
    @required this.accentColor,
    @required this.themeType,
    @required this.language,
    @required this.fontSize,
    @required this.chatFontSize,
    @required this.enterSend,
    @required this.onSelectPrimaryColor,
    @required this.onSelectAccentColor,
    @required this.onIncrementTheme,
    @required this.onToggleEnterSend,
    @required this.onToggleMembershipEvents,
  });

  static Props mapStoreToProps(Store<AppState> store) => Props(
        primaryColor: store.state.settingsStore.primaryColor ?? TETHERED_CYAN,
        accentColor: store.state.settingsStore.accentColor ?? TETHERED_CYAN,
        themeType: store.state.settingsStore.theme.toString(),
        language: store.state.settingsStore.language,
        enterSend: store.state.settingsStore.enterSend,
        fontSize: "Normal",
        chatFontSize: "Normal",
        onSelectPrimaryColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectPrimaryColor(color),
        ),
        onSelectAccentColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectAccentColor(color),
        ),
        onIncrementTheme: () => store.dispatch(
          incrementTheme(),
        ),
        onToggleMembershipEvents: () => store.dispatch(
          toggleEnterSend(),
        ),
        onToggleEnterSend: () => store.dispatch(
          toggleEnterSend(),
        ),
      );

  @override
  int get hashCode =>
      primaryColor.hashCode ^
      accentColor.hashCode ^
      language.hashCode ^
      themeType.hashCode ^
      enterSend.hashCode ^
      onSelectPrimaryColor.hashCode ^
      onSelectAccentColor.hashCode ^
      onIncrementTheme.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          primaryColor == other.primaryColor &&
          accentColor == other.accentColor &&
          language == other.language &&
          themeType == other.themeType &&
          enterSend == other.enterSend &&
          onSelectPrimaryColor == other.onSelectPrimaryColor &&
          onSelectAccentColor == other.onSelectAccentColor &&
          onIncrementTheme == other.onIncrementTheme;
}

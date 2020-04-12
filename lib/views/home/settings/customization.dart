import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/settings/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

class Customization extends StatelessWidget {
  Customization({Key key, this.title}) : super(key: key);

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
                onColorChange: (Color color) {
                  onSelectColor(color.value);
                },
                selectedColor: Colors.red),
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
          double height = MediaQuery.of(context).size.height;

          // Static horizontal: 16, vertical: 8
          final contentPadding = EdgeInsets.symmetric(
            horizontal: width * 0.08,
            vertical: height * 0.005,
          );

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
                ListTile(
                  onTap: () => props.onIncrementTheme(),
                  contentPadding: contentPadding,
                  title: Text(
                    'Theme',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: Text(
                    displayThemeType(props.themeType),
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                ListTile(
                  onTap: () => onShowColorPicker(
                    context: context,
                    onSelectColor: props.onSelectPrimaryColor,
                    originalColor: props.primaryColor,
                  ),
                  contentPadding: contentPadding,
                  title: Text(
                    'Primary Color',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(props.primaryColor),
                  ),
                ),
                ListTile(
                  onTap: () => onShowColorPicker(
                    context: context,
                    onSelectColor: props.onSelectAccentColor,
                    originalColor: props.accentColor,
                  ),
                  contentPadding: contentPadding,
                  title: Text(
                    'Accent Color',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(props.accentColor),
                  ),
                ),
                ListTile(
                  onTap: () {},
                  contentPadding: contentPadding,
                  title: Text(
                    'Language',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: Text(
                    props.language,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            )),
          );
        },
      );
}

class Props {
  final int primaryColor;
  final int accentColor;
  final String themeType;
  final String language;
  final Function onSelectPrimaryColor;
  final Function onSelectAccentColor;
  final Function onIncrementTheme;

  Props({
    @required this.primaryColor,
    @required this.accentColor,
    @required this.themeType,
    @required this.language,
    @required this.onSelectPrimaryColor,
    @required this.onSelectAccentColor,
    @required this.onIncrementTheme,
  });

  static Props mapStoreToProps(Store<AppState> store) => Props(
        primaryColor: store.state.settingsStore.primaryColor ?? TETHERED_CYAN,
        accentColor: store.state.settingsStore.accentColor ?? BESIDES_BLUE,
        themeType: store.state.settingsStore.theme.toString(),
        language: store.state.settingsStore.language,
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
      );

  @override
  int get hashCode =>
      primaryColor.hashCode ^
      accentColor.hashCode ^
      language.hashCode ^
      themeType.hashCode ^
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
          onSelectPrimaryColor == other.onSelectPrimaryColor &&
          onSelectAccentColor == other.onSelectAccentColor &&
          onIncrementTheme == other.onIncrementTheme;
}

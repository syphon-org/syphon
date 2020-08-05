// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';

class Theming extends StatelessWidget {
  Theming({Key key}) : super(key: key);

  displayThemeType(String themeTypeName) {
    return themeTypeName.split('.')[1].toLowerCase();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleThemeing,
                style: Theme.of(context).textTheme.headline6.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                  child: Column(
                children: <Widget>[
                  CardSection(
                    child: Column(
                      children: [
                        Container(
                          width: width,
                          padding: Dimensions.listPadding,
                          child: Text(
                            'App',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                DialogColorPicker(
                              title: 'Select Primary Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.primaryColor,
                              onSelectColor: props.onSelectPrimaryColor,
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Primary Color',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.primaryColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                DialogColorPicker(
                              title: 'Select Accent Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.primaryColor,
                              onSelectColor: props.onSelectAccentColor,
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Accent Color',
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.accentColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                DialogColorPicker(
                              title: 'Select App Bar Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.appBarColor,
                              onSelectColor: props.onSelectAppBarColor,
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'App Bar Color',
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.appBarColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => props.onIncrementTheme(),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Theme',
                          ),
                          trailing: Text(
                            displayThemeType(props.themeType),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CardSection(
                    child: Column(
                      children: [
                        Container(
                          width: width,
                          padding: Dimensions.listPadding,
                          child: Text(
                            'Fonts',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Font',
                          ),
                          trailing: Text(
                            props.fontName,
                          ),
                          onTap: () => props.onIncrementFontType(),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Font Size',
                          ),
                          trailing: Text(
                            props.fontSize,
                          ),
                          onTap: () => props.onIncrementFontSize(),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
            ),
          );
        },
      );
}

class Props extends Equatable {
  final int primaryColor;
  final int accentColor;
  final int appBarColor;
  final String themeType;
  final String language;
  final String fontName;
  final String fontSize;

  final Function onSelectPrimaryColor;
  final Function onSelectAccentColor;
  final Function onSelectAppBarColor;
  final Function onIncrementFontType;
  final Function onIncrementFontSize;
  final Function onIncrementTheme;

  Props({
    @required this.primaryColor,
    @required this.accentColor,
    @required this.appBarColor,
    @required this.themeType,
    @required this.language,
    @required this.fontName,
    @required this.fontSize,
    @required this.onSelectPrimaryColor,
    @required this.onSelectAccentColor,
    @required this.onSelectAppBarColor,
    @required this.onIncrementFontType,
    @required this.onIncrementFontSize,
    @required this.onIncrementTheme,
  });

  @override
  List<Object> get props => [
        primaryColor,
        accentColor,
        appBarColor,
        themeType,
        language,
        fontName,
        fontSize,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        primaryColor:
            store.state.settingsStore.primaryColor ?? Colours.cyanSyphon,
        accentColor:
            store.state.settingsStore.accentColor ?? Colours.cyanSyphon,
        appBarColor:
            store.state.settingsStore.appBarColor ?? Colours.cyanSyphon,
        themeType: store.state.settingsStore.theme.toString(),
        language: store.state.settingsStore.language,
        fontName: store.state.settingsStore.fontName,
        fontSize: store.state.settingsStore.fontSize,
        onSelectPrimaryColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectPrimaryColor(color),
        ),
        onSelectAccentColor: (int color) => store.dispatch(
          // convert to int hex color code
          selectAccentColor(color),
        ),
        onSelectAppBarColor: (int color) => store.dispatch(
          // convert to int hex color code
          updateAppBarColor(color),
        ),
        onIncrementFontType: () => store.dispatch(
          incrementFontType(),
        ),
        onIncrementFontSize: () => store.dispatch(
          incrementFontSize(),
        ),
        onIncrementTheme: () => store.dispatch(
          incrementTheme(),
        ),
      );
}

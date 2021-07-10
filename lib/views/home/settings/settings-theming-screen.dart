import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/string-keys.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';

class ThemingSettingsScreen extends StatefulWidget {
  const ThemingSettingsScreen({Key? key}) : super(key: key);

  @override
  _ThemingSettingsScreenState createState() => _ThemingSettingsScreenState();
}

class _ThemingSettingsScreenState extends State<ThemingSettingsScreen> {
  bool advancedColors = false;

  onToggleAdvancedColors(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DialogConfirm(
        title: 'Confirm Advanced Colors',
        content: Strings.contentAdvancedColorDialog,
        confirm: 'enable',
        onConfirm: () async {
          setState(() {
            advancedColors = true;
          });
          Navigator.pop(dialogContext);
        },
        onDismiss: () => Navigator.pop(dialogContext),
      ),
    );
  }

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
                tr(StringKeys.titleViewTheming),
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  CardSection(
                    child: Column(
                      children: [
                        Container(
                          width: width,
                          padding: Dimensions.listPadding,
                          child: Text(
                            'Color',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) => DialogColorPicker(
                              title: 'Select Primary Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.primaryColor,
                              onSelectColor: props.onSelectPrimaryColor,
                              advanced: advancedColors,
                              onToggleAdvanced: () => onToggleAdvancedColors(dialogContext),
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
                            builder: (BuildContext dialogContext) => DialogColorPicker(
                              title: 'Select Accent Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.accentColor,
                              onSelectColor: props.onSelectAccentColor,
                              advanced: advancedColors,
                              onToggleAdvanced: () => onToggleAdvancedColors(dialogContext),
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Accent Color',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.accentColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) => DialogColorPicker(
                              title: 'Select App Bar Color',
                              resetColor: Colours.cyanSyphon,
                              currentColor: props.appBarColor,
                              onSelectColor: props.onSelectAppBarColor,
                              advanced: advancedColors,
                              onToggleAdvanced: () => onToggleAdvancedColors(dialogContext),
                            ),
                          ),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'App Bar Color',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(props.appBarColor),
                          ),
                        ),
                        ListTile(
                          onTap: () => props.onIncrementThemeType(),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Theme',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.themeType,
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
                            style: Theme.of(context).textTheme.subtitle1,
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
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.fontSize,
                          ),
                          onTap: () => props.onIncrementFontSize(),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Message Size',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.messageSize,
                          ),
                          onTap: () => props.onIncrementMessageSize(),
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
                            'App',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        ListTile(
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Room Type Badges',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Switch(
                            value: props.roomTypeBadgesEnabled,
                            onChanged: (value) => props.onToggleRoomTypeBadges(),
                            activeColor: Color(props.primaryColor),
                          ),
                          onTap: () => props.onToggleRoomTypeBadges(),
                        ),
                        ListTile(
                          onTap: () => props.onIncrementAvatarShape(),
                          contentPadding: Dimensions.listPadding,
                          title: Text(
                            'Avatar Shape',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          trailing: Text(
                            props.avatarShape,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final int primaryColor;
  final int accentColor;
  final int appBarColor;
  final String themeType;
  final String language;
  final String fontName;
  final String fontSize;
  final String messageSize;
  final String avatarShape;

  final bool roomTypeBadgesEnabled;

  final Function onSelectPrimaryColor;
  final Function onSelectAccentColor;
  final Function onSelectAppBarColor;
  final Function onIncrementFontType;
  final Function onIncrementFontSize;
  final Function onIncrementMessageSize;
  final Function onIncrementThemeType;
  final Function onToggleRoomTypeBadges;
  final Function onIncrementAvatarShape;

  const _Props({
    required this.primaryColor,
    required this.accentColor,
    required this.appBarColor,
    required this.themeType,
    required this.language,
    required this.fontName,
    required this.fontSize,
    required this.messageSize,
    required this.avatarShape,
    required this.roomTypeBadgesEnabled,
    required this.onSelectPrimaryColor,
    required this.onSelectAccentColor,
    required this.onSelectAppBarColor,
    required this.onIncrementFontType,
    required this.onIncrementFontSize,
    required this.onIncrementThemeType,
    required this.onToggleRoomTypeBadges,
    required this.onIncrementAvatarShape,
    required this.onIncrementMessageSize,
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
        avatarShape,
        roomTypeBadgesEnabled,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        primaryColor: store.state.settingsStore.themeSettings.primaryColor,
        accentColor: store.state.settingsStore.themeSettings.accentColor,
        appBarColor: store.state.settingsStore.themeSettings.appBarColor,
        themeType: selectThemeTypeString(store.state.settingsStore.themeSettings.themeType),
        language: store.state.settingsStore.language,
        fontName: selectFontNameString(store.state.settingsStore.themeSettings.fontName),
        fontSize: selectFontSizeString(store.state.settingsStore.themeSettings.fontSize),
        messageSize: selectMessageSizeString(store.state.settingsStore.themeSettings.messageSize),
        avatarShape: selectAvatarShapeString(store.state.settingsStore.themeSettings.avatarShape),
        roomTypeBadgesEnabled: store.state.settingsStore.roomTypeBadgesEnabled,
        onToggleRoomTypeBadges: () => store.dispatch(
          toggleRoomTypeBadges(),
        ),
        onSelectPrimaryColor: (int color) => store.dispatch(
          // convert to int hex color code
          setPrimaryColor(color),
        ),
        onSelectAccentColor: (int color) => store.dispatch(
          // convert to int hex color code
          setAccentColor(color),
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
        onIncrementMessageSize: () => store.dispatch(
          incrementMessageSize(),
        ),
        onIncrementThemeType: () => store.dispatch(
          incrementThemeType(),
        ),
        onIncrementAvatarShape: () => store.dispatch(
          incrementAvatarShape(),
        ),
      );
}

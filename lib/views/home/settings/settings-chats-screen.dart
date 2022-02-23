import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

class ChatsSettingsScreen extends StatelessWidget {
  const ChatsSettingsScreen({Key? key}) : super(key: key);

  displayThemeType(String themeTypeName) {
    return themeTypeName.split('.')[1].toLowerCase();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Scaffold(
            appBar: AppBarNormal(
              title: Strings.titleChatSettings,
            ),
            body: SingleChildScrollView(
              child: Container(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: <Widget>[
                      CardSection(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: Dimensions.listPadding,
                              child: Text(
                                'General',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                onTap: () => Navigator.pushNamed(context, Routes.settingsLanguages),
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Language',
                                ),
                                trailing: Text(props.language!),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Show Membership Events',
                                ),
                                subtitle: Text(
                                  'Show membership changes within the chat',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                                trailing: Switch(
                                  value: false,
                                  inactiveThumbColor: Color(Colours.greyDisabled),
                                  onChanged: (showMembershipEvents) {},
                                ),
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
                                onChanged: (enterSend) => props.onToggleEnterSend(),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleAutocorrect(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(Strings.titleToggleAutocorrect),
                              subtitle: Text(
                                Strings.subtitleToggleAutocorrect,
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.autocorrect,
                                onChanged: (autocorrect) => props.onToggleAutocorrect(),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleSuggestions(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(Strings.titleToggleSuggestions),
                              subtitle: Text(
                                Strings.subtitleToggleSuggestions,
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.suggestions,
                                onChanged: (suggestions) => props.onToggleSuggestions(),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleTimeFormat(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                '24 Hour Time Format',
                              ),
                              subtitle: Text(
                                'Show message timestamps using 24 hour format',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.timeFormat24,
                                onChanged: (value) => props.onToggleTimeFormat(),
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleDismissKeyboard(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Dismiss Keyboard',
                              ),
                              subtitle: Text(
                                'Dismiss the keyboard after sending a message',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.dismissKeyboard,
                                onChanged: (value) => props.onToggleDismissKeyboard(),
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
                                'Ordering',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Sort By',
                                ),
                                trailing: Text(
                                  'Timestamp',
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'Group By',
                                ),
                                trailing: Text(
                                  'None',
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
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
                                'Media',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'View all uploaded Media',
                                ),
                                subtitle: Text(
                                  'See all uploaded data, even those unaccessible from messages',
                                  style: Theme.of(context).textTheme.caption,
                                ),
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
                                'Media auto-download',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              onTap: () => props.onToggleAutoDownload(),
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'Auto Download',
                              ),
                              subtitle: Text(
                                props.autoDownload ? 'On' : 'Off',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              trailing: Switch(
                                value: props.autoDownload,
                                onChanged: (enabled) => props.onToggleAutoDownload(),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'When using mobile data',
                                ),
                                subtitle: Text(
                                  'Images, Audio, Video, Files',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'When using Wi-Fi',
                                ),
                                subtitle: Text(
                                  'Images, Audio, Video, Files',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => props.onDisabled(),
                              child: ListTile(
                                enabled: false,
                                contentPadding: Dimensions.listPadding,
                                title: Text(
                                  'When Roaming',
                                ),
                                subtitle: Text(
                                  'Images, Audio, Video, Files',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
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
  final String? language;

  final bool enterSend;
  final bool autocorrect;
  final bool suggestions;
  final bool timeFormat24;
  final bool dismissKeyboard;
  final bool autoDownload;

  final Function onDisabled;
  final Function onIncrementLanguage;
  final Function onToggleEnterSend;
  final Function onToggleAutocorrect;
  final Function onToggleSuggestions;
  final Function onToggleTimeFormat;
  final Function onToggleAutoDownload;
  final Function onToggleDismissKeyboard;

  const Props({
    required this.language,
    required this.enterSend,
    required this.autocorrect,
    required this.suggestions,
    required this.timeFormat24,
    required this.dismissKeyboard,
    required this.autoDownload,
    required this.onDisabled,
    required this.onIncrementLanguage,
    required this.onToggleEnterSend,
    required this.onToggleAutocorrect,
    required this.onToggleSuggestions,
    required this.onToggleTimeFormat,
    required this.onToggleDismissKeyboard,
    required this.onToggleAutoDownload,
  });

  @override
  List<Object?> get props => [
        language,
        enterSend,
        autocorrect,
        suggestions,
        autoDownload,
        timeFormat24,
        dismissKeyboard,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        language: DisplayName(Locale(store.state.settingsStore.language)).toDisplayName(),
        enterSend: store.state.settingsStore.enterSendEnabled,
        autocorrect: store.state.settingsStore.autocorrectEnabled,
        suggestions: store.state.settingsStore.suggestionsEnabled,
        timeFormat24: store.state.settingsStore.timeFormat24Enabled,
        dismissKeyboard: store.state.settingsStore.dismissKeyboardEnabled,
        autoDownload: store.state.settingsStore.autoDownloadEnabled,
        onIncrementLanguage: () {
          store.dispatch(addInfo(
            message: Strings.alertAppRestartEffect,
            action: 'Dismiss',
          ));
          store.dispatch(incrementLanguage());
        },
        onDisabled: () => store.dispatch(addInProgress()),
        onToggleEnterSend: () => store.dispatch(toggleEnterSend()),
        onToggleAutocorrect: () => store.dispatch(toggleAutocorrect()),
        onToggleSuggestions: () => store.dispatch(toggleSuggestions()),
        onToggleTimeFormat: () => store.dispatch(toggleTimeFormat()),
        onToggleAutoDownload: () => store.dispatch(toggleAutoDownload()),
        onToggleDismissKeyboard: () => store.dispatch(toggleDismissKeyboard()),
      );
}

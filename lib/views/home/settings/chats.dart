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

class ChatPreferences extends StatelessWidget {
  ChatPreferences({Key key}) : super(key: key);

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
                Strings.titleChatPreferences,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
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
                            ListTile(
                              onTap: () {},
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
                              enabled: false,
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'When using mobile data',
                              ),
                              subtitle: Text(
                                'Images, Audio, Video, Documents, Other',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ),
                            ListTile(
                              enabled: false,
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'When using Wi-Fi',
                              ),
                              subtitle: Text(
                                'Images, Audio, Video, Documents, Other',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ),
                            ListTile(
                              enabled: false,
                              contentPadding: Dimensions.listPadding,
                              title: Text(
                                'When Roaming',
                              ),
                              subtitle: Text(
                                'Images, Audio, Video, Documents, Other',
                                style: Theme.of(context).textTheme.caption,
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
  final String language;
  final bool enterSend;
  final String chatFontSize;

  final Function onToggleEnterSend;

  Props({
    @required this.language,
    @required this.enterSend,
    @required this.chatFontSize,
    @required this.onToggleEnterSend,
  });

  @override
  List<Object> get props => [
        language,
        enterSend,
        chatFontSize,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        chatFontSize: 'Default',
        language: store.state.settingsStore.language,
        enterSend: store.state.settingsStore.enterSend,
        onToggleEnterSend: () => store.dispatch(toggleEnterSend()),
      );
}

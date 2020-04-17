import 'dart:async';

import 'package:Tether/domain/rooms/room/model.dart';
import 'package:Tether/domain/rooms/room/selectors.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/chat-avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:expandable/expandable.dart';

import 'package:redux/redux.dart';
import 'package:Tether/domain/matrix/actions.dart';

import 'package:Tether/domain/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Assets

class SearchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class GroupSearchScreen extends StatefulWidget {
  final String title;
  final Store<AppState> store;
  const GroupSearchScreen({Key key, this.title, this.store}) : super(key: key);

  @override
  GroupSearchScreenState createState() => GroupSearchScreenState(
        title: this.title,
        store: this.store,
      );
}

class GroupSearchScreenState extends State<GroupSearchScreen> {
  final String title;
  final Store<AppState> store;

  GroupSearchScreenState({
    Key key,
    this.title,
    this.store,
  });

  Timer searchTimeout;
  bool searching = false;
  Widget appBarTitle = Text('Search a topic...');

  @override
  void initState() {
    super.initState();

    appBarTitle = TouchableOpacity(
      activeOpacity: 0.4,
      onTap: () {
        setState(() {
          searching = !searching;
        });
      },
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          final mainBackgroundColor =
              Theme.of(context).brightness == Brightness.dark
                  ? null
                  : const Color(DISABLED_GREY);

          return Scaffold(
            backgroundColor: mainBackgroundColor,
            appBar: AppBar(
              brightness: Brightness.dark,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: !searching
                  ? appBarTitle
                  : TextField(
                      onChanged: (text) {
                        if (this.searchTimeout != null) {
                          this.searchTimeout.cancel();
                          this.searchTimeout = null;
                        }
                        this.setState(() {
                          searchTimeout =
                              new Timer(Duration(milliseconds: 400), () {
                            props.onSearch(text);
                          });
                        });
                      },
                      cursorColor: Colors.white,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w100,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search a topic...',
                        hintStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
              actions: <Widget>[
                IconButton(
                  color: Colors.white,
                  icon: Icon(searching ? Icons.cancel : Icons.search),
                  onPressed: () {
                    setState(() {
                      searching = !searching;
                    });
                  },
                  tooltip: 'Search Homeservers',
                ),
              ],
            ),
            body: Center(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                scrollDirection: Axis.vertical,
                itemCount: props.searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  final result = props.searchResults[index];
                  final sectionBackgroundColor =
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(BASICALLY_BLACK)
                          : const Color(BACKGROUND);

                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate.pushNamed(context, /home/messages/details
                    },
                    child: Card(
                      color: sectionBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: ExpandablePanel(
                          header: ListTile(
                            leading: CircleAvatar(
                              child: buildChatAvatar(room: result),
                            ),
                            title: Text(
                              formatRoomName(room: result),
                              style: TextStyle(
                                fontSize: 22.0,
                              ),
                            ),
                            subtitle: Text(
                              result.topic ?? '',
                            ),
                          ),
                          expanded: Row(
                            children: <Widget>[
                              Expanded(
                                  child: Column(children: <Widget>[
                                Text(
                                  'Encrypted Messages',
                                  softWrap: true,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  'No',
                                  softWrap: true,
                                )
                              ])),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      'Users',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                      ),
                                      softWrap: true,
                                    ),
                                    Text(
                                      '500',
                                      softWrap: true,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          tapHeaderToExpand: false,
                          hasIcon: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
}

class _Props {
  final bool loading;
  final ThemeType theme;
  final List<dynamic> searchResults;

  final Function onSearch;

  _Props({
    @required this.theme,
    @required this.loading,
    @required this.searchResults,
    @required this.onSearch,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        loading: false,
        theme: store.state.settingsStore.theme,
        searchResults: store.state.matrixStore.searchResults,
        onSearch: (text) {
          print('onSearch $text');
          store.dispatch(searchPublicRooms(searchText: text));
        },
      );

  @override
  int get hashCode => loading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Props &&
          runtimeType == other.runtimeType &&
          theme == other.theme &&
          loading == other.loading &&
          onSearch == other.onSearch;
}

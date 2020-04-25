import 'dart:async';

import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/store/rooms/room/selectors.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/chat-avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:expandable/expandable.dart';
import 'package:intl/intl.dart';

import 'package:redux/redux.dart';
import 'package:Tether/store/matrix/actions.dart';

import 'package:Tether/store/index.dart';
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
  final searchInputFocusNode = FocusNode();

  GroupSearchScreenState({
    Key key,
    this.title,
    this.store,
  });

  Timer searchTimeout;
  bool searching = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    if (!this.searching) {
      this.onToggleSearch(context: context);
    }

    // Initial search to show rooms by most popular
    if (store.state.matrixStore.searchResults.isEmpty) {
      store.dispatch(searchPublicRooms(searchText: ''));
    }
    searchInputFocusNode.addListener(() {
      if (!searchInputFocusNode.hasFocus) {
        searching = false;
      }
    });
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @protected
  void onToggleSearch({BuildContext context}) {
    setState(() {
      searching = !searching;
    });
    if (searching) {
      Timer(
        Duration(milliseconds: 1), // hack to focus after visibility change
        () => FocusScope.of(
          context,
        ).requestFocus(
          searchInputFocusNode,
        ),
      );
    } else {
      FocusScope.of(
        context,
      ).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
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
              title: Stack(
                children: [
                  Visibility(
                    visible: !searching,
                    child: TouchableOpacity(
                      activeOpacity: 0.4,
                      onTap: () => onToggleSearch(context: context),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    child: Visibility(
                      visible: searching,
                      maintainState: true,
                      child: TextField(
                        focusNode: searchInputFocusNode,
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
                        decoration: InputDecoration(
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.0,
                              color: Colors.transparent,
                            ),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.0,
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.0,
                              color: Colors.transparent,
                            ),
                          ),
                          hintText: 'Search a topic...',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                IconButton(
                  color: Colors.white,
                  icon: Icon(searching ? Icons.cancel : Icons.search),
                  onPressed: () => onToggleSearch(context: context),
                  tooltip: 'Search Homeservers',
                ),
              ],
            ),
            body: Center(
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    scrollDirection: Axis.vertical,
                    itemCount: props.searchResults.length,
                    itemBuilder: (BuildContext context, int index) {
                      final result = (props.searchResults[index] as Room);
                      final sectionBackgroundColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(BASICALLY_BLACK)
                              : const Color(BACKGROUND);

                      final formattedUserTotal = NumberFormat.compact();
                      final localUserTotal = NumberFormat();
                      return GestureDetector(
                        onTap: () {
                          // TODO: Navigate.pushNamed(context, /home/messages/details
                        },
                        child: Card(
                          color: sectionBackgroundColor,
                          elevation: 0,
                          child: Container(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: ExpandablePanel(
                              hasIcon: false,
                              tapBodyToCollapse: true,
                              tapHeaderToExpand: true,
                              header: Container(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: result.avatar != null
                                        ? Colors.transparent
                                        : Colors.grey,
                                    child: buildChatAvatar(room: result),
                                  ),
                                  title: Text(
                                    formatRoomName(room: result),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Visibility(
                                        visible:
                                            result.encryptionEnabled == null ||
                                                !result.encryptionEnabled,
                                        child: Container(
                                          child: Icon(
                                            Icons.lock_open,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                          left: 4,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person,
                                            ),
                                            Text(
                                              formattedUserTotal.format(
                                                  result.totalJoinedUsers),
                                              style: TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              collapsed: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        formatPreviewTopic(result.topic),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            Theme.of(context).textTheme.caption,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              expanded: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      result.topic ?? 'No Topic Available',
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      result.name,
                                      textAlign: TextAlign.start,
                                      softWrap: true,
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                                child: !result.encryptionEnabled
                                                    ? Icon(
                                                        Icons.lock_open,
                                                        size: 24.0,
                                                        color: Colors.redAccent,
                                                      )
                                                    : Icon(
                                                        Icons.lock,
                                                        size: 24.0,
                                                        color:
                                                            Colors.greenAccent,
                                                      ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'Encryption',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .caption,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                                child: Text(
                                                  localUserTotal.format(
                                                      result.totalJoinedUsers),
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'Total Users',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .caption,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    child: Visibility(
                      visible: props.loading,
                      child: Container(
                          margin: EdgeInsets.only(top: height * 0.02),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              RefreshProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                  PRIMARY_COLOR,
                                ),
                                value: null,
                              ),
                            ],
                          )),
                    ),
                  ),
                ],
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
        loading: store.state.matrixStore.loading,
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

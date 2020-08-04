import 'dart:async';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/image-matrix.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:expandable/expandable.dart';
import 'package:intl/intl.dart';

import 'package:redux/redux.dart';
import 'package:syphon/store/search/actions.dart';

import 'package:syphon/store/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Assets

class SearchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class GroupSearchView extends StatefulWidget {
  const GroupSearchView({Key key}) : super(key: key);

  @override
  GroupSearchState createState() => GroupSearchState();
}

class GroupSearchState extends State<GroupSearchView> {
  final searchInputFocusNode = FocusNode();

  GroupSearchState({Key key});

  Timer searchTimeout;
  bool searching = false;

  // componentDidMount(){}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() async {
    final store = StoreProvider.of<AppState>(context);
    final searchResults = store.state.searchStore.searchResults;

    if (!this.searching) {
      this.onToggleSearch(context: context);
    }

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && !(searchResults[0] is Room)) {
      store.dispatch(clearSearchResults());
    }
    // Initial search to show rooms by most popular
    if (store.state.searchStore.searchResults.isEmpty) {
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
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          // final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;

          return Scaffold(
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
                        Strings.titleSearchGroups,
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
                      vertical: 4,
                      horizontal: 2,
                    ),
                    scrollDirection: Axis.vertical,
                    itemCount: props.searchResults.length,
                    itemBuilder: (BuildContext context, int index) {
                      final room = (props.searchResults[index] as Room);
                      final formattedUserTotal = NumberFormat.compact();
                      final localUserTotal = NumberFormat();

                      return Container(
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
                              leading: Stack(
                                children: [
                                  AvatarCircle(
                                    uri: room.avatarUri,
                                    alt: room.name,
                                  ),
                                  Visibility(
                                    visible: !room.encryptionEnabled,
                                    child: Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.thumbnailSizeMax,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red,
                                                offset: Offset(8.0, 8.0),
                                              )
                                            ],
                                          ),
                                          height: 16,
                                          width: 16,
                                          child: Icon(
                                            Icons.lock_open,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: room.encryptionEnabled,
                                    child: Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.thumbnailSizeMax,
                                        ),
                                        child: Container(
                                          height: 16,
                                          width: 16,
                                          color: Colors.green,
                                          child: Icon(
                                            Icons.lock,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    formatRoomName(room: room),
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.subtitle1,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formattedUserTotal.format(
                                            room.totalJoinedUsers,
                                          ),
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
                                      color: Colors.greenAccent,
                                      size: Dimensions.iconSize,
                                    ),
                                    iconSize: Dimensions.iconSize,
                                    onPressed: () async {
                                      await props.onJoin(room: room);
                                      Navigator.pop(context);
                                    },
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
                                    formatPreviewTopic(room.topic),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.caption,
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
                                  room.topic ?? 'No Topic Available',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  room.name,
                                  textAlign: TextAlign.start,
                                  softWrap: true,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: !room.encryptionEnabled
                                                ? Icon(
                                                    Icons.lock_open,
                                                    size: 24.0,
                                                    color: Colors.redAccent,
                                                  )
                                                : Icon(
                                                    Icons.lock,
                                                    size: 24.0,
                                                    color: Colors.greenAccent,
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
                                                  room.totalJoinedUsers),
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
                                strokeWidth: Dimensions.defaultStrokeWidth,
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
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

class _Props extends Equatable {
  final bool loading;
  final ThemeType theme;
  final List<dynamic> searchResults;

  final Function onJoin;
  final Function onSearch;

  _Props({
    @required this.theme,
    @required this.loading,
    @required this.searchResults,
    @required this.onJoin,
    @required this.onSearch,
  });

  @override
  List<Object> get props => [
        theme,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.searchStore.loading,
        theme: store.state.settingsStore.theme,
        searchResults: store.state.searchStore.searchResults,
        onJoin: ({Room room}) {
          store.dispatch(joinRoom(room: room));
        },
        onSearch: (text) {
          store.dispatch(searchPublicRooms(searchText: text));
        },
      );
}

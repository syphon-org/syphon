import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/scheduler.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:expandable/expandable.dart';

import 'package:redux/redux.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/search/actions.dart';

import 'package:syphon/store/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

class SearchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class HomeSearch extends StatefulWidget {
  final String title;
  const HomeSearch({Key key, this.title}) : super(key: key);

  @override
  HomeSearchState createState() => HomeSearchState(title: this.title);
}

class HomeSearchState extends State<HomeSearch> {
  final String title;
  final Store<AppState> store;
  final searchInputFocusNode = FocusNode();

  bool searching = false;
  Widget appBarTitle = Text(Strings.titleHomeserverSearch);
  HomeSearchState({Key key, this.title, this.store});

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

    if (store.state.searchStore.homeservers.isEmpty) {
      store.dispatch(fetchHomeservers());
    }

    appBarTitle = TouchableOpacity(
      activeOpacity: 0.4,
      onTap: () {
        setState(() {
          searching = !searching;
        });
      },
      child: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
      ),
    );
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
          final height = MediaQuery.of(context).size.height;
          print(props.homeservers.length);
          return Scaffold(
            appBar: AppBar(
              brightness: Brightness.dark,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Stack(children: [
                Visibility(
                  visible: !searching,
                  child: TouchableOpacity(
                    activeOpacity: 0.4,
                    onTap: () {
                      setState(() {
                        searching = !searching;
                      });
                    },
                    child: Text(
                      Strings.titleHomeserverSearch,
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
                      onSubmitted: (text) {
                        props.onSearch(text);
                      },
                      onChanged: (text) {
                        props.onSearch(text);
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
                        hintText: Strings.placeholderHomeserverSearch,
                        hintStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
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
                children: <Widget>[
                  ListView.builder(
                    padding: const EdgeInsets.all(8),
                    scrollDirection: Axis.vertical,
                    itemCount: props.homeservers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final homeserver = props.homeservers[index] ?? Map();

                      return GestureDetector(
                        onTap: () {
                          props.onSelect(homeserver: homeserver);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: ExpandablePanel(
                            hasIcon: true,
                            tapHeaderToExpand: false,
                            header: ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: homeserver['favicon'] != null
                                      ? Colors.transparent
                                      : Colors.grey,
                                  child: homeserver['favicon'] != null
                                      ? Image(
                                          width: 75,
                                          height: 75,
                                          image: NetworkImage(
                                            homeserver['favicon'],
                                          ),
                                        )
                                      : Text(
                                          homeserver['hostname']
                                              .toString()
                                              .substring(0, 2)
                                              .toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1,
                                        )),
                              title: Text(
                                homeserver['hostname'],
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              subtitle: Text(
                                homeserver['description'],
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ),
                            expanded: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Column(children: <Widget>[
                                  Text(
                                    'Location',
                                    style: Theme.of(context).textTheme.caption,
                                    softWrap: true,
                                  ),
                                  Text(
                                    homeserver['location'],
                                    softWrap: true,
                                  )
                                ])),
                                Expanded(
                                    child: Column(children: <Widget>[
                                  Text(
                                    'Users',
                                    style: Theme.of(context).textTheme.caption,
                                    softWrap: true,
                                  ),
                                  homeserver['users_active'] != null
                                      ? Text(
                                          homeserver['users_active'].toString(),
                                          softWrap: true,
                                        )
                                      : Text(
                                          homeserver['public_room_count']
                                              .toString(),
                                          softWrap: true,
                                        ),
                                ])),
                                Expanded(
                                    child: Column(children: <Widget>[
                                  Text(
                                    'Founded',
                                    style: Theme.of(context).textTheme.caption,
                                    softWrap: true,
                                  ),
                                  Text(
                                    homeserver['online_since'].toString(),
                                    softWrap: true,
                                  ),
                                ])),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'Avg Speed',
                                        style:
                                            Theme.of(context).textTheme.caption,
                                        softWrap: true,
                                      ),
                                      Text(
                                        homeserver['last_response_time']
                                                .toString() +
                                            'ms',
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Visibility(
                    visible: props.searchText != null &&
                        props.searchText.isNotEmpty &&
                        props.homeservers.isEmpty,
                    child: GestureDetector(
                      onTap: () {
                        final homeserver = {
                          'hostname': props.searchText,
                        };
                        props.onSelect(homeserver: homeserver);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 8,
                          top: 16,
                          bottom: 16,
                          right: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              props.searchText
                                  .toString()
                                  .substring(
                                      0,
                                      props.searchText.length < 2
                                          ? props.searchText.length
                                          : 2)
                                  .toUpperCase(),
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            backgroundColor: Colors.grey,
                          ),
                          title: Text(
                            props.searchText,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          subtitle: Text(
                            'Try logging in with this server',
                            style: Theme.of(context).textTheme.caption.merge(
                                  TextStyle(fontStyle: FontStyle.italic),
                                ),
                          ),
                        ),
                      ),
                    ),
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

class _Props extends Equatable {
  final bool loading;
  final String searchText;
  final List<dynamic> homeservers;
  final Function onSearch;
  final Function onSelect;

  _Props({
    @required this.loading,
    @required this.homeservers,
    @required this.searchText,
    @required this.onSelect,
    @required this.onSearch,
  });

  @override
  List<Object> get props => [
        loading,
        searchText,
        homeservers,
      ];

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        loading: store.state.searchStore.loading,
        searchText: store.state.searchStore.searchText ?? '',
        homeservers: store.state.searchStore.searchText != null
            ? store.state.searchStore.searchResults
            : store.state.searchStore.homeservers,
        onSelect: ({homeserver}) {
          store.dispatch(selectHomeserver(homeserver: homeserver));
        },
        onSearch: (text) {
          store.dispatch(searchHomeservers(searchText: text));
        },
      );
}

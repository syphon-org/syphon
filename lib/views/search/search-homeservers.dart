// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/search/actions.dart';

class SearchHomeservers extends StatefulWidget {
  const SearchHomeservers({Key key}) : super(key: key);

  @override
  SearchHomeserversState createState() => SearchHomeserversState();
}

class SearchHomeserversState extends State<SearchHomeservers> {
  final Store<AppState> store;
  final searchInputFocusNode = FocusNode();

  bool searching = false;
  SearchHomeserversState({Key key, this.store});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    if (!this.searching) {
      this.setState(() {
        searching = true;
      });
    }

    if (store.state.searchStore.homeservers.isEmpty) {
      store.dispatch(fetchHomeservers());
    }
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final height = MediaQuery.of(context).size.height;
          return Scaffold(
            appBar: AppBarSearch(
              title: Strings.titleHomeserverSearch,
              label: Strings.placeholderHomeserverSearch,
              tooltip: 'Search Homeservers',
              brightness: Brightness.dark,
              focusNode: searchInputFocusNode,
              forceFocus: true,
              onChange: (text) {
                props.onSearch(text);
              },
              onSearch: (text) {
                props.onSearch(text);
              },
              onToggleSearch: () => this.setState(() {
                searching = !searching;
              }),
            ),
            body: Center(
              child: Stack(
                children: <Widget>[
                  ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: props.homeservers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final homeserver = props.homeservers[index] ?? Map();

                      return GestureDetector(
                        onTap: () {
                          props.onSelect(homeserver: homeserver);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: ExpandablePanel(
                            hasIcon: true,
                            tapHeaderToExpand: false,
                            header: ListTile(
                              leading: AvatarCircle(
                                size: Dimensions.avatarSizeMin,
                                url: homeserver['favicon'],
                                alt: homeserver['hostname'],
                                background:
                                    Colours.hashedColor(homeserver['hostname']),
                              ),
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
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'Location',
                                        style:
                                            Theme.of(context).textTheme.caption,
                                        softWrap: true,
                                      ),
                                      Text(
                                        homeserver['location'] ?? '',
                                        softWrap: true,
                                      )
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'Users',
                                        style:
                                            Theme.of(context).textTheme.caption,
                                        softWrap: true,
                                      ),
                                      homeserver['users_active'] != null
                                          ? Text(
                                              homeserver['users_active']
                                                  .toString(),
                                              softWrap: true,
                                            )
                                          : Text(
                                              homeserver['public_room_count']
                                                  .toString(),
                                              softWrap: true,
                                            ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'Founded',
                                        style:
                                            Theme.of(context).textTheme.caption,
                                        softWrap: true,
                                      ),
                                      Text(
                                        homeserver['online_since'].toString(),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
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
                                        (homeserver['last_response_time'] ?? '')
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
                    child: Container(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          final homeserver = {
                            'hostname': props.searchText,
                          };
                          props.onSelect(homeserver: homeserver);
                          Navigator.pop(context);
                        },
                        child: ListTile(
                          leading: AvatarCircle(
                            alt: props.searchText ?? '',
                            size: Dimensions.avatarSizeMin,
                            background: props.searchText.length > 0
                                ? Colours.hashedColor(props.searchText)
                                : Colors.grey,
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
                                value: null,
                                strokeWidth: Dimensions.defaultStrokeWidth,
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
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

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.searchStore.loading,
        searchText: store.state.searchStore.searchText ?? '',
        homeservers: store.state.searchStore.searchText != null
            ? store.state.searchStore.searchResults
            : store.state.searchStore.homeservers,
        onSelect: ({Map homeserver}) {
          store.dispatch(selectHomeserver(homeserver: homeserver));
        },
        onSearch: (text) {
          store.dispatch(searchHomeservers(searchText: text));
        },
      );
}

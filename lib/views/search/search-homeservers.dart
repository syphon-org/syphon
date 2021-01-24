// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/string-keys.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
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
              title: tr(StringKeys.titleViewHomeserverSearch),
              label: tr(StringKeys.labelSearchHomeservers),
              tooltip: 'Search Homeservers',
              brightness: Brightness.dark,
              focusNode: searchInputFocusNode,
              throttle: Duration(milliseconds: 500),
              forceFocus: true,
              onChange: (text) {
                props.onSearch(text);
              },
              onSearch: (text) {
                props.onSearch(text);

                if (props.searchText.isNotEmpty && props.homeservers.isEmpty) {
                  props.onFetchHomeserverPreview(text);
                }
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
                      final Homeserver homeserver =
                          props.homeservers[index] ?? Map();

                      return GestureDetector(
                        onTap: () {
                          props.onSelect(homeserver.hostname);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: ExpandablePanel(
                            hasIcon: true,
                            tapHeaderToExpand: false,
                            header: ListTile(
                              leading: Avatar(
                                size: Dimensions.avatarSizeMin,
                                url: homeserver.photoUrl,
                                alt: homeserver.hostname,
                                background:
                                    Colours.hashedColor(homeserver.hostname),
                              ),
                              title: Text(
                                homeserver.hostname,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              subtitle: Text(
                                homeserver.description,
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
                                        homeserver.location ?? '',
                                        softWrap: true,
                                      )
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: homeserver.usersActive != null,
                                  child: Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          'Users',
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption,
                                          softWrap: true,
                                        ),
                                        Text(
                                          homeserver.usersActive ?? '',
                                          softWrap: true,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: homeserver.roomsTotal != null &&
                                      homeserver.usersActive == null,
                                  child: Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          'Rooms',
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption,
                                          softWrap: true,
                                        ),
                                        Text(
                                          homeserver.roomsTotal ?? '',
                                          softWrap: true,
                                        )
                                      ],
                                    ),
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
                                        homeserver.founded.toString(),
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
                                        homeserver.responseTime + 'ms',
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
                        props.searchText.length > 0 &&
                        props.homeservers.isEmpty,
                    child: Container(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          props.onSelect(props.searchText);
                          Navigator.pop(context);
                        },
                        child: ListTile(
                          leading: Avatar(
                            alt: props.searchText ?? '',
                            size: Dimensions.avatarSizeMin,
                            url: props.homeserver.photoUrl != null
                                ? props.homeserver.photoUrl
                                : null,
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
  final Homeserver homeserver;
  final Function onSearch;
  final Function onSelect;
  final Function onFetchHomeserverPreview;

  _Props({
    @required this.loading,
    @required this.homeservers,
    @required this.searchText,
    @required this.homeserver,
    @required this.onSelect,
    @required this.onSearch,
    @required this.onFetchHomeserverPreview,
  });

  @override
  List<Object> get props => [
        loading,
        searchText,
        homeservers,
        homeserver,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.searchStore.loading,
        searchText: store.state.searchStore.searchText ?? '',
        homeservers: store.state.searchStore.searchText != null
            ? store.state.searchStore.searchResults
            : store.state.searchStore.homeservers,
        homeserver: store.state.authStore.homeserver ?? Homeserver(),
        onSelect: (String hostname) {
          store.dispatch(selectHomeserver(hostname: hostname));
        },
        onSearch: (text) {
          store.dispatch(searchHomeservers(searchText: text));
        },
        onFetchHomeserverPreview: (String hostname) async {
          var urlRegex = new RegExp(Values.urlRegex, caseSensitive: false);

          if (urlRegex.hasMatch('https://$hostname')) {
            final preview = await store.dispatch(
              fetchHomeserver(hostname: hostname),
            );

            await store.dispatch(setHomeserver(homeserver: preview));
          }
        },
      );
}

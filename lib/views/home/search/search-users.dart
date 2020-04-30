import 'dart:async';

import 'package:Tether/global/colors.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/store/user/model.dart';
import 'package:Tether/store/user/selectors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';

import 'package:redux/redux.dart';
import 'package:Tether/store/search/actions.dart';

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

class SearchUserView extends StatefulWidget {
  final String title;
  final Store<AppState> store;
  const SearchUserView({Key key, this.title, this.store}) : super(key: key);

  @override
  SearchUserState createState() => SearchUserState(
        title: this.title,
        store: this.store,
      );
}

class SearchUserState extends State<SearchUserView> {
  final String title;
  final Store<AppState> store;
  final searchInputFocusNode = FocusNode();

  SearchUserState({
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

    final searchResults = store.state.matrixStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && !(searchResults[0] is User)) {
      store.dispatch(clearSearchResults());
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

  @protected
  Widget buildUserAvatar({User user}) {
    if (user.avatarUrl != null && user.avatarUrl.contains('mxc')) {
      return Container(
        margin: EdgeInsets.all(8),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
          value: null,
        ),
      );
    }

    if (user.avatarUrl != null && !user.avatarUrl.contains('mxc')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image(
          width: 52,
          height: 52,
          image: NetworkImage(user.avatarUrl),
        ),
      );
    }

    return Text(
      displayInitials(user),
      style: TextStyle(fontSize: 18, color: Colors.white),
    );
  }

  @override
  buildUserList(BuildContext context, _Props props) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 4,
      ),
      scrollDirection: Axis.vertical,
      itemCount: props.searchResults.length,
      itemBuilder: (BuildContext context, int index) {
        final user = (props.searchResults[index] as User);
        final sectionBackgroundColor =
            Theme.of(context).brightness == Brightness.dark
                ? const Color(BASICALLY_BLACK)
                : const Color(BACKGROUND);

        final formattedUserTotal = NumberFormat.compact();
        final localUserTotal = NumberFormat();

        final avatarWidget = buildUserAvatar(user: user);

        return GestureDetector(
          onTap: () {
            // TODO:
          },
          child: Card(
            color: sectionBackgroundColor,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: avatarWidget,
                  backgroundColor:
                      avatarWidget is Text ? Colors.grey : Colors.transparent,
                ),
                title: Text(
                  formatDisplayName(user),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  user.userId,
                  style: TextStyle(
                    color: props.loading ? Color(DISABLED_GREY) : null,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48.0,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(48),
                        onTap: () {
                          Navigator.pushNamed(context, '/home/draft');
                        },
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
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
                          hintText: 'Search for a user...',
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
                  tooltip: 'Search users',
                ),
              ],
            ),
            body: Center(
              child: Stack(
                children: [
                  buildUserList(context, props),
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

class _Props extends Equatable {
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
          store.dispatch(searchUsers(searchText: text));
        },
      );

  @override
  List<Object> get props => [
        loading,
        theme,
        searchResults,
      ];
}

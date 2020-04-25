import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:expandable/expandable.dart';

import 'package:redux/redux.dart';
import 'package:Tether/store/user/actions.dart';
import 'package:Tether/store/matrix/actions.dart';
import 'package:Tether/store/matrix/selectors.dart';

import 'package:Tether/store/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:Tether/store/user/model.dart';

// Assets

class SearchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class HomeSearch extends StatefulWidget {
  final String title;
  final Store<AppState> store;
  const HomeSearch({Key key, this.title, this.store}) : super(key: key);

  @override
  HomeSearchState createState() => HomeSearchState(
        title: this.title,
        store: this.store,
      );
}

class HomeSearchState extends State<HomeSearch> {
  final String title;
  final Store<AppState> store;

  Widget appBarTitle = Text('Find a homeserver');
  bool searching = false;
  HomeSearchState({Key key, this.title, this.store});

  @override
  void initState() {
    super.initState();

    if (store.state.matrixStore.homeservers.length <= 0) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: searching
            ? StoreConnector<AppState, UserStore>(
                converter: (Store<AppState> store) => store.state.userStore,
                builder: (context, userStore) {
                  return TextField(
                      onChanged: (text) {
                        store.dispatch(searchHomeservers(searchText: text));
                      },
                      cursorColor: Colors.white,
                      cursorRadius: Radius.circular(25),
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w100),
                      decoration: InputDecoration.collapsed(
                        hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w100),
                        hintText: 'Search by keywords',
                      ));
                })
            : appBarTitle,
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
        child: StoreConnector<AppState, List<dynamic>>(
          converter: (Store<AppState> store) => searchResults(store.state),
          builder: (context, homeservers) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.vertical,
              itemCount: homeservers.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    store.dispatch(
                        selectHomeserver(homeserver: homeservers[index]));
                    Navigator.pop(context);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: ExpandablePanel(
                        header: ListTile(
                          leading: CircleAvatar(
                              backgroundColor: Colors.grey[100],
                              child: homeservers[index]['favicon'] != null
                                  ? Image(
                                      width: 75,
                                      height: 75,
                                      image: NetworkImage(
                                          homeservers[index]['favicon']),
                                    )
                                  : Text(
                                      homeservers[index]['hostname']
                                          .toString()
                                          .substring(0, 2)
                                          .toUpperCase(),
                                      style: TextStyle(color: Colors.black),
                                    )),
                          title: Text(
                            homeservers[index]['hostname'],
                            style:
                                TextStyle(fontSize: 22.0, color: Colors.black),
                          ),
                          subtitle: Text(homeservers[index]['description']),
                        ),
                        expanded: Row(
                          children: <Widget>[
                            Expanded(
                                child: Column(children: <Widget>[
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                ),
                                softWrap: true,
                              ),
                              Text(
                                homeservers[index]['location'],
                                softWrap: true,
                              )
                            ])),
                            Expanded(
                                child: Column(children: <Widget>[
                              Text(
                                'Users',
                                style: TextStyle(fontWeight: FontWeight.w400),
                                softWrap: true,
                              ),
                              homeservers[index]['users_active'] != null
                                  ? Text(
                                      homeservers[index]['users_active']
                                          .toString(),
                                      softWrap: true,
                                    )
                                  : Text(
                                      homeservers[index]['public_room_count']
                                          .toString(),
                                      softWrap: true,
                                    ),
                            ])),
                            Expanded(
                                child: Column(children: <Widget>[
                              Text(
                                'Founded',
                                style: TextStyle(fontWeight: FontWeight.w400),
                                softWrap: true,
                              ),
                              Text(
                                homeservers[index]['online_since'].toString(),
                                softWrap: true,
                              ),
                            ])),
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    'Avg Speed',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w400),
                                    softWrap: true,
                                  ),
                                  Text(
                                    homeservers[index]['last_response_time']
                                            .toString() +
                                        'ms',
                                    softWrap: true,
                                  ),
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
            );
          },
        ),
      ),
    );
  }
}

import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/domain/user/selectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:redux/redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'package:Tether/domain/user/model.dart';

class SearchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class OnboardingSearchScreen extends StatefulWidget {
  final String title;
  const OnboardingSearchScreen({Key key, this.title}) : super(key: key);

  @override
  OnboardingSearchScreenState createState() =>
      OnboardingSearchScreenState(title: this.title);
}

class OnboardingSearchScreenState extends State<OnboardingSearchScreen> {
  final String title;
  Widget appBarTitle = Text('Find a homeserver');
  bool searching = false;
  OnboardingSearchScreenState({Key key, this.title});

  @override
  void initState() {
    store.dispatch(fetchHomeservers());
    appBarTitle = TouchableOpacity(
        activeOpacity: 0.4,
        onTap: () {
          setState(() {
            searching = !searching;
          });
        },
        child: Text(title,
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w100)));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

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
                  shrinkWrap: true,
                  itemCount: homeservers.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        onTap: () {
                          store.dispatch(
                              setHomeserver(homeserver: homeservers[index]));
                          Navigator.pop(context);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              homeservers[index]['hostname'],
                              style: TextStyle(
                                  fontSize: 22.0, color: Colors.black),
                            ),
                          ),
                        ));
                  },
                );
              })),
    );
  }
}

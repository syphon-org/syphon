import 'package:Tether/domain/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';

import 'package:Tether/domain/chat/actions.dart';

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

  OnboardingSearchScreenState({Key key, this.title});

  @override
  void initState() {
    store.dispatch(fetchHomeservers());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: Text(title,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
        ),
        body: Center(
            child: ScrollConfiguration(
          behavior: SearchScrollBehavior(),
          child: SingleChildScrollView(
            child: Container(
                height: height,
                width: width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: width * 0.9,
                      height: 54,
                      margin: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                      constraints: BoxConstraints(
                          minWidth: 200, maxWidth: 600, minHeight: 45),
                      child: TextField(
                          cursorRadius: Radius.circular(25),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0)),
                            // hintStyle: TextStyle(decoration: ),
                            labelText: 'Search Homeservers',
                            hintText: 'matrix.org, potato.xyz, etc',
                          )),
                    ),
                    Text(
                      'Please Render',
                      style: Theme.of(context).textTheme.display1,
                    )
                  ],
                )),
          ),
        )));
  }
}

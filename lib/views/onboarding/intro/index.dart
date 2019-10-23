import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/model.dart';

import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_svg/flutter_svg.dart';

import './landing.dart';
import './understanding.dart';
import './possibilities.dart';
import './explination.dart';
import './action.dart';

class IntroScreen extends StatefulWidget {
  final String title;
  const IntroScreen({Key key, this.title}) : super(key: key);

  IntroScreenState createState() => IntroScreenState(title: this.title);
}

class IntroScreenState extends State<IntroScreen> {
  final String title;
  SwiperController controller;
  final double DEFAULT_INPUT_HEIGHT = 52;
  final double DEFAULT_BUTTON_HEIGHT = 48;

  final sections = [
    LandingSection(),
    UnderstandingSection(),
    ExplinationSection(),
    PossibilitiesSection(),
    ActionSection(),
  ];

  IntroScreenState({Key key, this.title});

  @override
  void initState() {
    controller = new SwiperController();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              width: width,
              height: height,
              constraints:
                  BoxConstraints(minWidth: 125, minHeight: 200, maxHeight: 400),
              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  return sections[index];
                },
                loop: false,
                itemCount: 5,
                controller: controller,
              )),
          SizedBox(height: height * 0.125),
          StoreConnector<AppState, UserStore>(
            converter: (Store<AppState> store) => store.state.userStore,
            builder: (context, userStore) {
              return Container(
                width: width * 0.7,
                height: DEFAULT_BUTTON_HEIGHT,
                margin: const EdgeInsets.all(10.0),
                constraints:
                    BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 45),
                child: FlatButton(
                  onPressed: () {
                    controller.next(animation: true);
                  },
                  color: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0)),
                  child: const Text('Let\'s Go',
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              );
            },
          ),
        ],
      )),
    );
  }
}

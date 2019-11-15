import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/model.dart';

// Styling Widgets
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import './landing.dart';
import './first.dart';
import './second.dart';
import './third.dart';
import './action.dart';

final double DEFAULT_INPUT_HEIGHT = 52;
final double DEFAULT_BUTTON_HEIGHT = 48;

class IntroScreen extends StatefulWidget {
  final String title;
  const IntroScreen({Key key, this.title}) : super(key: key);

  IntroScreenState createState() => IntroScreenState(title: this.title);
}

class IntroScreenState extends State<IntroScreen> {
  final String title;

  final sections = [
    LandingSection(),
    FirstSection(),
    SecondSection(),
    ThirdSection(),
    ActionSection(),
  ];

  int currentStep = 0;
  bool onboarding = false;
  String loginText = 'Already have a username?';
  SwiperController controller;

  IntroScreenState({Key key, this.title});

  @override
  void initState() {
    controller = new SwiperController();
  }

  Widget buildButtonText() {
    switch (currentStep) {
      case 0:
        return const Text('Let\'s Go',
            style: TextStyle(fontSize: 20, color: Colors.white));
      case 4:
        return const Text('Count Me In',
            style: TextStyle(fontSize: 20, color: Colors.white));
      default:
        return const Text('Next',
            style: TextStyle(fontSize: 20, color: Colors.white));
    }
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
          Spacer(flex: 8),
          Container(
              width: width,
              height: height * 0.6,
              constraints:
                  BoxConstraints(minWidth: 125, minHeight: 345, maxHeight: 400),
              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  return sections[index];
                },
                onIndexChanged: (index) {
                  setState(() {
                    currentStep = index;
                  });
                },
                loop: false,
                itemCount: 5,
                controller: controller,
              )),
          Spacer(flex: 9),
          StoreConnector<AppState, UserStore>(
            converter: (Store<AppState> store) => store.state.userStore,
            builder: (context, userStore) {
              return Container(
                width: width * 0.7,
                height: DEFAULT_BUTTON_HEIGHT,
                margin: const EdgeInsets.all(10.0),
                constraints: BoxConstraints(
                    minWidth: 200, maxWidth: 400, minHeight: 45, maxHeight: 65),
                child: FlatButton(
                    onPressed: () {
                      if (currentStep == 0) {
                        setState(() {
                          onboarding = true;
                        });
                      }
                      if (currentStep == sections.length - 2) {
                        setState(() {
                          loginText = 'Already created a matrix user?';
                          onboarding = false;
                        });
                      }

                      if (currentStep == sections.length - 1) {
                        return Navigator.pushNamed(
                          context,
                          '/signup',
                        );
                      }

                      controller.next(animation: true);
                    },
                    color: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(30.0)),
                    child: buildButtonText()),
              );
            },
          ),
          Spacer(flex: 1),
          Container(
              height: DEFAULT_INPUT_HEIGHT,
              margin: const EdgeInsets.all(10.0),
              constraints: BoxConstraints(minWidth: 200, minHeight: 45),
              child: Visibility(
                  visible: !onboarding,
                  child: TouchableOpacity(
                      activeOpacity: 0.4,
                      onTap: () => Navigator.pushNamed(
                            context,
                            '/login',
                          ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            loginText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w100,
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                )),
                          ),
                        ],
                      )))),
          Spacer(flex: 1),
        ],
      )),
    );
  }
}

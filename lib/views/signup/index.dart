import 'dart:async';

import 'package:Tether/domain/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/model.dart';

// Styling Widgets
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:Tether/global/dimensions.dart';

import './step-username.dart';
import './step-password.dart';
import './step-homeserver.dart';

class DefaultScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class Signup extends StatefulWidget {
  final String title;
  const Signup({Key key, this.title}) : super(key: key);

  SignupState createState() => SignupState(title: this.title);
}

class SignupState extends State<Signup> {
  final String title;
  final sections = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
  ];

  int currentStep = 0;
  bool onboarding = false;
  bool validStep = false;
  SwiperController controller;
  StreamSubscription subscription;

  SignupState({Key key, this.title});

  @override
  void initState() {
    controller = new SwiperController();
    subscription = store.onChange.listen((state) {
      if (state.userStore.user.accessToken != null) {
        final String currentRoute = ModalRoute.of(context).settings.name;
        print('Subscription is working');
        if (currentRoute != 'home') {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      }
    });
    super.initState();
  }

  @override
  void deactivate() {
    subscription.cancel();
    super.deactivate();
  }

  Function onCheckStepValidity(UserStore userStore) {
    switch (this.currentStep) {
      case 0:
        return userStore.isHomeserverValid
            ? () {
                controller.next(animation: true);
              }
            : null;
      case 1:
        return userStore.isUsernameValid
            ? () {
                controller.next(animation: true);
              }
            : null;
      case 2:
        return !userStore.isPasswordValid
            ? null
            : () {
                store.dispatch(createUser());
                setState(() {
                  currentStep = 3;
                });
              };
      default:
        return null;
    }
  }

  Widget buildButtonText() {
    switch (currentStep) {
      case 2:
        return const Text('Finish',
            style: TextStyle(fontSize: 20, color: Colors.white));
      default:
        return const Text('Continue',
            style: TextStyle(fontSize: 20, color: Colors.white));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ScrollConfiguration(
          behavior: DefaultScrollBehavior(),
          child: SingleChildScrollView(
              child: Container(
                  height: height,
                  width: width,
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                          width: width,
                          height: height * 0.7,
                          constraints: BoxConstraints(
                              minWidth: 125, minHeight: 345, maxHeight: height),
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
                      Spacer(flex: 8),
                      StoreConnector<AppState, UserStore>(
                        converter: (Store<AppState> store) =>
                            store.state.userStore,
                        builder: (context, userStore) {
                          return Container(
                            width: width * 0.7,
                            height: DEFAULT_BUTTON_HEIGHT,
                            margin: const EdgeInsets.all(10.0),
                            constraints: BoxConstraints(
                                minWidth: 200,
                                maxWidth: 400,
                                minHeight: 45,
                                maxHeight: 65),
                            child: FlatButton(
                                disabledColor: Colors.grey,
                                disabledTextColor: Colors.grey[300],
                                onPressed: onCheckStepValidity(userStore),
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                                child: !userStore.creating
                                    ? buildButtonText()
                                    : CircularProgressIndicator(
                                        backgroundColor: Colors.white,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.grey),
                                      )),
                          );
                        },
                      ),
                      Spacer(flex: 4),
                    ],
                  )))),
    );
  }
}

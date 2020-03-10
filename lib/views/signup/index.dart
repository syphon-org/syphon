import 'dart:async';

import 'package:Tether/domain/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/model.dart';

// Styling Widgets
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/behaviors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import './step-username.dart';
import './step-password.dart';
import './step-homeserver.dart';

class Signup extends StatefulWidget {
  final String title;
  final Store<AppState> store;
  const Signup({Key key, this.title, this.store}) : super(key: key);

  SignupState createState() =>
      SignupState(title: this.title, store: this.store);
}

class SignupState extends State<Signup> {
  final String title;
  final Store<AppState> store;

  final sections = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
  ];

  int currentStep = 0;
  bool onboarding = false;
  bool validStep = false;
  bool naving = false;
  StreamSubscription subscription;
  PageController pageController;

  SignupState({Key key, this.title, this.store});

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );
    subscription = store.onChange.listen((state) {
      // toggle button to a creating user state
      if (state.userStore.creating && this.currentStep != 3) {
        setState(() {
          currentStep = 3;
        });
        // otherwise let them retry
      } else if (!state.userStore.creating && this.currentStep == 3) {
        setState(() {
          currentStep = 2;
        });
      }

      if (state.userStore.user.accessToken != null) {
        final String currentRoute = ModalRoute.of(context).settings.name;
        print('Subscription is working $currentRoute');
        if (currentRoute != '/home' && !naving) {
          setState(() {
            naving = true;
          });
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      }
    });
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
                pageController.nextPage(
                  duration: Duration(milliseconds: 350),
                  curve: Curves.ease,
                );
              }
            : null;
      case 1:
        return userStore.isUsernameValid
            ? () {
                pageController.nextPage(
                  duration: Duration(milliseconds: 350),
                  curve: Curves.ease,
                );
              }
            : null;
      case 2:
        return !userStore.isPasswordValid
            ? null
            : () {
                store.dispatch(createUser());
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
    final appBar = AppBar(
      elevation: 0,
      iconTheme: IconThemeData(
        color: Color(store.state.settingsStore.primaryColor),
      ),
      backgroundColor: Colors.transparent,
      brightness: Brightness.light,
    );

    // TODO: document
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    // -
    //     MediaQuery.of(context).viewPadding.top -
    //     appBar.preferredSize.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
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
                Flexible(
                  flex: 11,
                  fit: FlexFit.tight,
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.end,
                    direction: Axis.vertical,
                    children: <Widget>[
                      Container(
                        width: width,
                        margin: EdgeInsets.only(top: 64, bottom: 32),
                        constraints: BoxConstraints(
                          minHeight: 326,
                          maxHeight: 400,
                          minWidth: 200,
                        ),
                        child: PageView(
                          physics: NeverScrollableScrollPhysics(),
                          pageSnapping: true,
                          allowImplicitScrolling: false,
                          controller: pageController,
                          children: sections,
                          onPageChanged: (index) {
                            setState(() {
                              currentStep = index;
                              onboarding =
                                  index != 0 && index != sections.length - 1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.end,
                    direction: Axis.vertical,
                    children: <Widget>[
                      StoreConnector<AppState, UserStore>(
                        converter: (Store<AppState> store) =>
                            store.state.userStore,
                        builder: (context, userStore) => Container(
                          width: width * 0.725,
                          height: DEFAULT_BUTTON_HEIGHT,
                          constraints: BoxConstraints(
                            minWidth: 256,
                            maxWidth: 400,
                            minHeight: DEFAULT_BUTTON_HEIGHT,
                            maxHeight: 65,
                          ),
                          child: FlatButton(
                            disabledColor: Colors.grey,
                            disabledTextColor: Colors.grey[300],
                            onPressed: onCheckStepValidity(userStore),
                            color: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: !userStore.creating
                                ? buildButtonText()
                                : CircularProgressIndicator(
                                    backgroundColor: Colors.white,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                  constraints: BoxConstraints(
                    minHeight: 45,
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SmoothPageIndicator(
                        controller: pageController, // PageController
                        count: sections.length,
                        effect: WormEffect(
                          spacing: 16,
                          dotHeight: 12,
                          dotWidth: 12,
                          activeDotColor: Color(
                            store.state.settingsStore.primaryColor,
                          ),
                        ), // your preferred effect
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

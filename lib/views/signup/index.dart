import 'dart:async';

import 'package:Tether/store/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/model.dart';

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

  @protected
  void onBackStep(BuildContext context) {
    if (this.currentStep < 1) {
      Navigator.pop(context, false);
    } else {
      this.setState(() {
        currentStep = this.currentStep - 1;
      });
      pageController.animateToPage(
        this.currentStep,
        duration: Duration(milliseconds: 275),
        curve: Curves.easeInOut,
      );
    }
  }

  @protected
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        brightness: Brightness.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Color(store.state.settingsStore.primaryColor)),
          onPressed: () {
            onBackStep(context);
            // ?Navigator.pop(context, false)
          },
        ),
      ),
      body: ScrollConfiguration(
        behavior: DefaultScrollBehavior(),
        child: SingleChildScrollView(
          child: Container(
            width: width, // set actual height and width for flex constraints
            height: height, // set actual height and width for flex constraints
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  flex: 8,
                  fit: FlexFit.tight,
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Container(
                        width: width,
                        padding: EdgeInsets.only(bottom: height * 0.05),
                        constraints: BoxConstraints(
                          minHeight: Dimensions.pageViewerHeightMin,
                          maxHeight: Dimensions.pageViewerHeightMax,
                        ),
                        child: PageView(
                          pageSnapping: true,
                          allowImplicitScrolling: false,
                          controller: pageController,
                          physics: NeverScrollableScrollPhysics(),
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
                          // EXAMPLE OF WIDGET PROPORTIONAL SCALING
                          width: width * 0.725,
                          height: Dimensions.inputHeight,
                          constraints: BoxConstraints(
                            minWidth: Dimensions.buttonWidthMin,
                            maxWidth: Dimensions.buttonWidthMax,
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

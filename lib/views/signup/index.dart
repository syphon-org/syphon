import 'dart:async';

import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/signup/step-captcha.dart';
import 'package:syphon/views/signup/step-terms.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:syphon/store/index.dart';

// Styling Widgets
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/behaviors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import './step-username.dart';
import './step-password.dart';
import './step-homeserver.dart';

final Duration nextAnimationDuration = Duration(
  milliseconds: 350,
);

class SignupView extends StatefulWidget {
  const SignupView({Key key}) : super(key: key);

  SignupViewState createState() => SignupViewState();
}

class SignupViewState extends State<SignupView> {
  final String title = Strings.titleViewSignup;

  int currentStep = 0;
  bool onboarding = false;
  bool validStep = false;
  bool naving = false;
  StreamSubscription subscription;
  PageController pageController;

  List<Widget> sections = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
  ];

  SignupViewState({Key key});

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: true,
      viewportFraction: 1.5,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() async {
    final store = StoreProvider.of<AppState>(context);

    // Init change listener
    subscription = store.onChange.listen((state) async {
      if (state.authStore.interactiveAuths.isNotEmpty &&
          this.sections.length < 4) {
        final newSections = List<Widget>.from(sections);

        newSections.add(CaptchaStep());
        newSections.add(TermsStep());

        setState(() {
          sections = newSections;
        });
      }

      if (state.authStore.user.accessToken != null) {
        final String currentRoute = ModalRoute.of(context).settings.name;
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
  Function onCheckStepValidity(_Props props, PageController controller) {
    print(
      '[onCheckStepValidity] new value',
    );
    switch (this.currentStep) {
      case 0:
        return props.isHomeserverValid
            ? () {
                controller.nextPage(
                  duration: nextAnimationDuration,
                  curve: Curves.ease,
                );
              }
            : null;
      case 1:
        return props.isUsernameValid && props.isUsernameAvailable
            ? () {
                controller.nextPage(
                  duration: nextAnimationDuration,
                  curve: Curves.ease,
                );
              }
            : null;
      case 2:
        return !props.isPasswordValid
            ? null
            : () async {
                if (sections.length < 4) {
                  final result = await props.onCreateUser();
                  if (!result) {
                    return await controller.nextPage(
                      duration: nextAnimationDuration,
                      curve: Curves.ease,
                    );
                  }
                }

                return await controller.nextPage(
                  duration: nextAnimationDuration,
                  curve: Curves.ease,
                );
              };
      case 3:
        return !props.captcha
            ? null
            : () async {
                var result = false;
                if (!props.completed.contains(MatrixAuthTypes.RECAPTCHA)) {
                  result = await props.onCreateUser();
                }
                if (!result) {
                  controller.nextPage(
                    duration: nextAnimationDuration,
                    curve: Curves.ease,
                  );
                }
              };
      case 4:
        return !props.agreement
            ? null
            : () async {
                final result = await props.onCreateUser();

                // If the user has a completed auth flow for matrix, reset to
                // proper auth type to attempt a real account creation
                // for matrix and try again
                if (result && props.user.accessToken == null) {
                  await props.onResetCredential();
                  props.onCreateUser();
                }
              };
      default:
        return null;
    }
  }

  Widget buildButtonText({BuildContext context}) {
    if (this.currentStep == sections.length - 1) {
      return Text(
        Strings.buttonSignupFinish,
        style: Theme.of(context).textTheme.button,
      );
    }

    return Text(
      Strings.buttonSignupNext,
      style: Theme.of(context).textTheme.button,
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              brightness: Brightness.light,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  onBackStep(context);
                },
              ),
            ),
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                child: Container(
                  width:
                      width, // set actual height and width for flex constraints
                  height:
                      height, // set actual height and width for flex constraints
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
                                    onboarding = index != 0 &&
                                        index != sections.length - 1;
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
                            Container(
                              width: width * 0.725,
                              margin: EdgeInsets.only(top: height * 0.01),
                              height: Dimensions.inputHeight,
                              constraints: BoxConstraints(
                                minWidth: Dimensions.buttonWidthMin,
                                maxWidth: Dimensions.buttonWidthMax,
                              ),
                              child: FlatButton(
                                key: Key(sections.length.toString() +
                                    this.currentStep.toString()),
                                disabledColor: Colors.grey,
                                disabledTextColor: Colors.grey[300],
                                onPressed: onCheckStepValidity(
                                  props,
                                  this.pageController,
                                ),
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: !props.creating
                                    ? buildButtonText(context: context)
                                    : CircularProgressIndicator(
                                        strokeWidth:
                                            Dimensions.defaultStrokeWidthLite,
                                        backgroundColor: Colors.white,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.grey,
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
                          vertical: 20,
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
                                activeDotColor: Theme.of(context).primaryColor,
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
        },
      );
}

class _Props extends Equatable {
  final User user;
  final String username;
  final bool isUsernameValid;
  final bool isUsernameAvailable;

  final String password;
  final bool isPasswordValid;

  final String homeserver;
  final bool isHomeserverValid;

  final bool creating;
  final bool captcha;
  final bool agreement;

  final List<String> completed;

  final Map interactiveAuths;

  final Function onCreateUser;
  final Function onResetCredential;

  _Props({
    @required this.user,
    @required this.username,
    @required this.isUsernameValid,
    @required this.isUsernameAvailable,
    @required this.password,
    @required this.isPasswordValid,
    @required this.homeserver,
    @required this.isHomeserverValid,
    @required this.creating,
    @required this.captcha,
    @required this.agreement,
    @required this.interactiveAuths,
    @required this.completed,
    @required this.onCreateUser,
    @required this.onResetCredential,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        completed: store.state.authStore.completed,
        username: store.state.authStore.username,
        isUsernameValid: store.state.authStore.isUsernameValid,
        isUsernameAvailable: store.state.authStore.isUsernameAvailable,
        password: store.state.authStore.password,
        isPasswordValid: store.state.authStore.isPasswordValid,
        homeserver: store.state.authStore.homeserver,
        isHomeserverValid: store.state.authStore.isHomeserverValid,
        creating: store.state.authStore.creating,
        captcha: store.state.authStore.captcha,
        agreement: store.state.authStore.agreement,
        interactiveAuths: store.state.authStore.interactiveAuths,
        onResetCredential: () async {
          await store.dispatch(updateCredential(
            type: MatrixAuthTypes.DUMMY,
          ));
        },
        onCreateUser: () async {
          return await store.dispatch(createUser());
        },
      );

  @override
  List<Object> get props => [
        user,
        username,
        isUsernameValid,
        isUsernameAvailable,
        password,
        isPasswordValid,
        homeserver,
        isHomeserverValid,
        creating,
        captcha,
        agreement,
        interactiveAuths,
      ];
}

import 'dart:io';

import 'package:Tether/global/assets.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/store/index.dart';

// Styling Widgets
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:Tether/global/dimensions.dart';

// Local Components
import './landing.dart';
import './first.dart';
import './second.dart';
import './third.dart';
import './action.dart';

class Intro extends StatefulWidget {
  const Intro({Key key}) : super(key: key);

  IntroState createState() => IntroState();
}

class IntroState extends State<Intro> {
  final String title = 'Intro';

  int currentStep = 0;
  bool onboarding = false;
  String loginText = Strings.buttonIntroExistQuestion;
  PageController pageController;

  final List<Widget> sections = [
    LandingSection(),
    FirstSection(),
    SecondSection(),
    ThirdSection(),
    ActionSection(),
  ];

  IntroState({Key key});

  @override
  void initState() {
    super.initState();

    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    // init authenticated navigation

    final store = StoreProvider.of<AppState>(context);
    final alphaAgreement = store.state.settingsStore.alphaAgreement;
    double width = MediaQuery.of(context).size.width;

    if (alphaAgreement == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        child: Container(
          constraints: BoxConstraints(
            minWidth: width * 0.9,
          ),
          child: SimpleDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Confirm Alpha TOS Agreement",
              textAlign: TextAlign.center,
            ),
            titlePadding: EdgeInsets.only(left: 24, right: 24, top: 24),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(24),
                child: Image(
                  width: 98,
                  height: 98,
                  image: AssetImage(Assets.appIconPng),
                ),
              ),
              Text(
                Strings.confirmationAlphaVersion,
                textAlign: TextAlign.center,
              ),
              Text(
                Strings.confirmationAppTermsOfService,
                style: TextStyle(fontSize: 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleDialogOption(
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: FlatButton(
                      child: Text('I Agree'),
                      onPressed: () async {
                        await store.dispatch(acceptAgreement());
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
      // showDialog(
      //   barrierDismissible: false,
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: Text("Confirm Alpha TOS Agreement"),
      //     content: Text(
      //       Strings.confirmationAlphaVersion,
      //     ),
      //     actions: <Widget>[
      //       FlatButton(
      //         child: Text('I Agree'),
      //         onPressed: () async {
      //           store.dispatch(acceptAgreement());
      //           Navigator.of(context).pop();
      //         },
      //       ),
      //     ],
      //   ),
      // );
    }
  }

  Widget buildButtonText() {
    switch (currentStep) {
      case 0:
        return Text(
          'let\'s go',
          style: Theme.of(context).textTheme.button,
        );
      case 4:
        return Text(
          'count me in',
          style: Theme.of(context).textTheme.button,
        );
      default:
        return Text(
          'next',
          style: Theme.of(context).textTheme.button,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final double widgetWidthScaling = width * 0.725;
    return Scaffold(
      body: StoreConnector<AppState, AppState>(
        converter: (Store<AppState> store) => store.state,
        builder: (context, state) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 6,
              fit: FlexFit.tight,
              child: Container(
                height: widgetWidthScaling,
                constraints: BoxConstraints(
                  minWidth: 125,
                  minHeight: 345,
                  maxHeight: 400,
                ),
                child: PageView(
                  pageSnapping: true,
                  allowImplicitScrolling: true,
                  controller: pageController,
                  children: sections,
                  onPageChanged: (index) {
                    setState(() {
                      currentStep = index;
                      onboarding = index != 0 && index != sections.length - 1;
                    });
                  },
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: widgetWidthScaling,
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minWidth: Dimensions.buttonWidthMin,
                      maxWidth: Dimensions.buttonWidthMax,
                    ),
                    child: FlatButton(
                      onPressed: () {
                        if (currentStep == 0) {
                          setState(() {
                            onboarding = true;
                          });
                        }

                        if (currentStep == sections.length - 2) {
                          setState(() {
                            loginText = Strings.buttonIntroExistQuestion;
                            onboarding = false;
                          });
                        }

                        if (currentStep == sections.length - 1) {
                          Navigator.pushNamed(
                            context,
                            '/signup',
                          );
                        }

                        pageController.nextPage(
                          duration: Duration(milliseconds: 350),
                          curve: Curves.ease,
                        );
                      },
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(30.0),
                      ),
                      child: buildButtonText(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: Dimensions.inputHeight,
              constraints: BoxConstraints(
                minHeight: Dimensions.inputHeight,
              ),
              margin: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 16,
                bottom: 24,
              ),
              child: onboarding
                  ? Flex(
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
                            paintStyle: PaintingStyle.fill,
                            strokeWidth: 12,
                            activeDotColor: Theme.of(context).primaryColor,
                          ), // your preferred effect
                        ),
                      ],
                    )
                  : TouchableOpacity(
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
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              Strings.buttonIntroExistAction,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  .copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

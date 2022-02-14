import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

import 'widgets/page-action.dart';
import 'widgets/page-description-first.dart';
import 'widgets/page-description-second.dart';
import 'widgets/page-description-third.dart';
import 'widgets/page-landing.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  IntroScreenState createState() => IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> with Lifecycle<IntroScreen> {
  final String title = 'Intro';

  int currentStep = 0;
  bool onboarding = false;
  bool showingTerms = false;
  String loginText = Strings.buttonTextLoginQuestion;
  PageController? pageController;
  BuildContext? dialogContext;

  final List<Widget> sections = [
    LandingPage(),
    FirstDescriptionPage(),
    SecondDescriptionPage(),
    ThirdDescriptionPage(),
    ActionPage(),
  ];

  IntroScreenState();

  @override
  void initState() {
    super.initState();

    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );
  }

  @override
  onMounted() async {
    final store = StoreProvider.of<AppState>(context);
    // TODO: should load from storageMiddleware -> state for settings instead
    final alphaAgreement = await loadTermsAgreement();
    final double width = MediaQuery.of(context).size.width;

    if (alphaAgreement == 0) {
      final termsTitle = Platform.isIOS ? Strings.titleDialogTerms : Strings.titleDialogTermsAlpha;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          dialogContext = dialogContext;
          return Container(
            constraints: BoxConstraints(
              minWidth: width * 0.9,
            ),
            child: SimpleDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                termsTitle,
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
                  Strings.confirmThanks,
                  textAlign: TextAlign.center,
                ),
                Visibility(
                  visible: !Platform.isIOS,
                  child: Text(
                    Strings.confirmAlphaVersion,
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible: !Platform.isIOS,
                  child: Text(
                    Strings.confirmAlphaWarning,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w100),
                  ),
                ),
                Text(
                  Strings.confirmAlphaWarningAlt,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w300),
                ),
                Text(
                  Strings.confirmTermsOfServiceConclusion,
                  textAlign: TextAlign.center,
                ),
                Text(
                  Strings.confirmAppTermsOfService,
                  style: TextStyle(fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: TextButton(
                        onPressed: () async {
                          await store.dispatch(acceptAgreement());
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(
                          Strings.buttonTextAgreement,
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    if (dialogContext != null) {
      Navigator.pop(dialogContext!);
    }
    super.dispose();
  }

  buildButtonString() {
    switch (currentStep) {
      case 0:
        return 'let\'s go';
      case 4:
        return 'count me in';
      default:
        return 'next';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: StoreConnector<AppState, AppState>(
          distinct: true,
          converter: (Store<AppState> store) => store.state,
          builder: (context, state) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                flex: 6,
                fit: FlexFit.tight,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: Dimensions.mediaSizeMin,
                  ),
                  child: PageView(
                    pageSnapping: true,
                    allowImplicitScrolling: true,
                    controller: pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentStep = index;
                        onboarding = index != 0 && index != sections.length - 1;
                      });
                    },
                    children: sections,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ButtonSolid(
                      text: buildButtonString(),
                      onPressed: () {
                        if (currentStep == 0) {
                          setState(() {
                            onboarding = true;
                          });
                        }

                        if (currentStep == sections.length - 2) {
                          setState(() {
                            loginText = Strings.buttonTextLoginQuestion;
                            onboarding = false;
                          });
                        }

                        if (currentStep == sections.length - 1) {
                          Navigator.pushNamed(context, Routes.signup);
                        }

                        pageController!.nextPage(
                          duration: Duration(
                            milliseconds: Values.animationDurationDefault,
                          ),
                          curve: Curves.ease,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  mainAxisAlignment: MainAxisAlignment.center,
                  direction: Axis.vertical,
                  children: <Widget>[
                    Container(
                      height: Dimensions.inputHeight,
                      constraints: BoxConstraints(
                        minHeight: Dimensions.inputHeight,
                      ),
                      child: onboarding
                          ? Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SmoothPageIndicator(
                                  controller: pageController!, // PageController
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
                              onTap: () => Navigator.pushNamed(context, Routes.login),
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
                                    child: Text(
                                      Strings.buttonTextLogin,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyText2!.copyWith(
                                            color: Theme.of(context).primaryColor,
                                            decoration: TextDecoration.underline,
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
            ],
          ),
        ),
      );
}

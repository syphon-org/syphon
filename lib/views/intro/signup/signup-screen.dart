import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:syphon/views/behaviors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/intro/signup/widgets/StepCaptcha.dart';
import 'package:syphon/views/intro/signup/widgets/StepEmail.dart';
import 'package:syphon/views/intro/signup/widgets/StepTerms.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'widgets/StepHomeserver.dart';
import 'widgets/StepPassword.dart';
import 'widgets/StepUsername.dart';

// Styling Widgets
final Duration nextAnimationDuration = Duration(
  milliseconds: Values.animationDurationDefault,
);

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  int currentStep = 0;
  bool validStep = false;
  bool onboarding = false;
  late StreamSubscription subscription;
  PageController? pageController;

  List<Widget> sections = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
  ];

  SignupScreenState({Key? key});

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: true,
      viewportFraction: 1.5,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() async {
    final store = StoreProvider.of<AppState>(context);

    final props = _Props.mapStateToProps(store);

    if (props.homeserver.loginType == MatrixAuthTypes.SSO) {
      setState(() {
        sections = sections
          ..removeWhere((step) => step.runtimeType != HomeserverStep);
      });
    }

    // Init change listener
    subscription = store.onChange.listen((state) async {
      if (state.authStore.interactiveAuths.isNotEmpty &&
          this.sections.length < 4) {
        final newSections = List<Widget>.from(sections);

        List<dynamic>? newStages = [];
        try {
          newStages = state.authStore.interactiveAuths['flows'][0]['stages'];
        } catch (error) {
          debugPrint('Failed to parse stages');
        }

        // dynamically add stages based on homeserver requirements
        newStages!.forEach((stage) {
          switch (stage) {
            case MatrixAuthTypes.EMAIL:
              newSections.add(EmailStep());
              break;
            case MatrixAuthTypes.RECAPTCHA:
              newSections.add(CaptchaStep());
              break;
            case MatrixAuthTypes.TERMS:
              newSections.add(TermsStep());
              break;
            default:
              break;
          }
        });

        setState(() {
          sections = newSections;
        });
      }
    });
  }

  @protected
  void onDidChange(_Props? oldProps, _Props props) {
    if (props.homeserver.loginType == MatrixAuthTypes.SSO) {
      setState(() {
        sections = sections
          ..removeWhere((step) => step.runtimeType != HomeserverStep);
      });
    }
    if (props.homeserver.loginType == MatrixAuthTypes.PASSWORD) {
      setState(() {
        sections = [
          HomeserverStep(),
          UsernameStep(),
          PasswordStep(),
        ];
      });
    }
  }

  @override
  void deactivate() {
    subscription.cancel();
    super.deactivate();
  }

  @protected
  void onBackStep(BuildContext context) {
    if (currentStep < 1) {
      Navigator.pop(context, false);
    } else {
      setState(() {
        currentStep = currentStep - 1;
      });
      pageController!.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 275),
        curve: Curves.easeInOut,
      );
    }
  }

  @protected
  bool? onCheckStepValid(_Props props, PageController? controller) {
    final currentSection = sections[currentStep];

    switch (currentSection.runtimeType) {
      case HomeserverStep:
        return props.isHomeserverValid;
      case UsernameStep:
        return props.isUsernameValid &&
            props.isUsernameAvailable &&
            !props.loading;
      case PasswordStep:
        return props.isPasswordValid;
      case EmailStep:
        return props.isEmailValid;
      case CaptchaStep:
        return props.captcha;
      case TermsStep:
        return props.agreement;
      default:
        return null;
    }
  }

  @protected
  Function? onCompleteStep(_Props props, PageController? controller) {
    final currentSection = sections[currentStep];
    final lastStep = (sections.length - 1) == currentStep;
    switch (currentSection.runtimeType) {
      case HomeserverStep:
        return () async {
          bool? valid = true;

          if (props.hostname != props.homeserver.hostname) {
            valid = await props.onSelectHomeserver(props.hostname);
          }

          if (props.homeserver.loginType == MatrixAuthTypes.SSO) {
            valid = false; // don't do anything else
            await props.onLoginSSO();
          }

          if (valid!) {
            controller!.nextPage(
              duration: nextAnimationDuration,
              curve: Curves.ease,
            );
          }
        };
      case UsernameStep:
        return () {
          controller!.nextPage(
            duration: nextAnimationDuration,
            curve: Curves.ease,
          );
        };
      case PasswordStep:
        return () async {
          if (sections.length < 4) {
            final result = await props.onCreateUser();

            // If signup is completed here, just wait for auth redirect
            if (result) {
              return;
            }
          }

          return controller!.nextPage(
            duration: nextAnimationDuration,
            curve: Curves.ease,
          );
        };
      case CaptchaStep:
        return () async {
          bool? result = false;
          if (!props.completed.contains(MatrixAuthTypes.RECAPTCHA)) {
            result = await props.onCreateUser(enableErrors: lastStep);
          }
          if (!result!) {
            controller!.nextPage(
              duration: nextAnimationDuration,
              curve: Curves.ease,
            );
          }
        };
      case TermsStep:
        return () async {
          bool? result = false;
          if (!props.completed.contains(MatrixAuthTypes.TERMS)) {
            result = await props.onCreateUser(enableErrors: lastStep);
          }
          if (!result!) {
            return controller!.nextPage(
              duration: nextAnimationDuration,
              curve: Curves.ease,
            );
          }

          // If the user has a completed auth flow for matrix.org, reset to
          // proper auth type to attempt a real account creation
          // for matrix and try again
          if (result && props.user.accessToken == null) {
            await props.onResetCredential();
            props.onCreateUser();
          }
        };
      case EmailStep:
        return () async {
          bool? result = false;
          final validEmail = await props.onSubmitEmail();

          // don't run anything if email is already in use
          if (!validEmail) {
            return false;
          }

          // try using email signup without verification
          if (!props.completed.contains(MatrixAuthTypes.EMAIL)) {
            result = await props.onCreateUser(enableErrors: lastStep);
          }

          // otherwise, send to the verification holding page
          if (!result!) {
            if (lastStep) {
              return Navigator.pushNamed(context, '/verification');
            }

            // or continue if not the last step
            controller!.nextPage(
              duration: nextAnimationDuration,
              curve: Curves.ease,
            );
          }
        };
      default:
        return null;
    }
  }

  String buildButtonString(_Props props) {
    if (props.homeserver.loginType == MatrixAuthTypes.SSO) {
      return Strings.buttonLoginSSO;
    }

    if (currentStep == sections.length - 1) {
      return Strings.buttonSignupFinish;
    }

    return Strings.buttonSignupNext;
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        onDidChange: onDidChange,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

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
                                onPageChanged: (index) {
                                  setState(() {
                                    currentStep = index;
                                    onboarding = index != 0 &&
                                        index != sections.length - 1;
                                  });
                                },
                                children: sections,
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
                            ButtonSolid(
                              text: buildButtonString(props),
                              loading: props.creating || props.loading,
                              disabled: props.creating ||
                                  !onCheckStepValid(
                                    props,
                                    pageController,
                                  )!,
                              onPressed: onCompleteStep(
                                props,
                                pageController,
                              ),
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
                              constraints: BoxConstraints(
                                minHeight: Dimensions.buttonHeightMin,
                              ),
                              child: Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SmoothPageIndicator(
                                    controller:
                                        pageController!, // PageController
                                    count: sections.length,
                                    effect: WormEffect(
                                      spacing: 16,
                                      dotHeight: 12,
                                      dotWidth: 12,
                                      activeDotColor:
                                          Theme.of(context).primaryColor,
                                    ), // your preferred effect
                                  ),
                                ],
                              ),
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

  final String hostname;
  final Homeserver homeserver;
  final bool isHomeserverValid;

  final String username;
  final bool isUsernameValid;
  final bool isUsernameAvailable;

  final String password;
  final bool isPasswordValid;

  final String email;
  final bool isEmailValid;

  final bool creating;
  final bool captcha;
  final bool agreement;
  final bool loading;
  final bool verificationNeeded;

  final List<String> completed;

  final Map interactiveAuths;

  final Function onLoginSSO;
  final Function onCreateUser;
  final Function onSubmitEmail;
  final Function onResetCredential;
  final Function onSelectHomeserver;

  const _Props({
    required this.user,
    required this.hostname,
    required this.homeserver,
    required this.isHomeserverValid,
    required this.username,
    required this.isUsernameValid,
    required this.isUsernameAvailable,
    required this.password,
    required this.isPasswordValid,
    required this.email,
    required this.isEmailValid,
    required this.creating,
    required this.captcha,
    required this.agreement,
    required this.loading,
    required this.verificationNeeded,
    required this.interactiveAuths,
    required this.completed,
    required this.onLoginSSO,
    required this.onCreateUser,
    required this.onSubmitEmail,
    required this.onResetCredential,
    required this.onSelectHomeserver,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        user: store.state.authStore.user,
        completed: store.state.authStore.completed,
        hostname: store.state.authStore.hostname,
        homeserver: store.state.authStore.homeserver,
        isHomeserverValid: store.state.authStore.homeserver.valid &&
            !store.state.authStore.loading,
        username: store.state.authStore.username,
        isUsernameValid: store.state.authStore.isUsernameValid,
        isUsernameAvailable: store.state.authStore.isUsernameAvailable,
        password: store.state.authStore.password,
        isPasswordValid: store.state.authStore.isPasswordValid,
        email: store.state.authStore.email,
        isEmailValid: store.state.authStore.isEmailValid,
        creating: store.state.authStore.creating,
        captcha: store.state.authStore.captcha,
        agreement: store.state.authStore.agreement,
        loading: store.state.authStore.loading,
        interactiveAuths: store.state.authStore.interactiveAuths,
        verificationNeeded: store.state.authStore.verificationNeeded,
        onSubmitEmail: () async {
          return await store.dispatch(submitEmail());
        },
        onResetCredential: () async {
          await store.dispatch(updateCredential(
            type: MatrixAuthTypes.DUMMY,
          ));
        },
        onLoginSSO: () async {
          return await store.dispatch(loginUserSSO());
        },
        onCreateUser: ({bool? enableErrors}) async {
          return await store.dispatch(createUser(enableErrors: enableErrors));
        },
        onSelectHomeserver: (String hostname) async {
          return await store.dispatch(selectHomeserver(hostname: hostname));
        },
      );

  @override
  List<Object> get props => [
        user,
        homeserver,
        isHomeserverValid,
        username,
        isUsernameValid,
        isUsernameAvailable,
        password,
        isPasswordValid,
        email,
        isEmailValid,
        creating,
        captcha,
        agreement,
        loading,
        interactiveAuths,
        verificationNeeded,
      ];
}

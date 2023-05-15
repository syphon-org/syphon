import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/auth/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/intro/signup/widgets/StepCaptcha.dart';
import 'package:syphon/views/intro/signup/widgets/StepEmail.dart';
import 'package:syphon/views/intro/signup/widgets/StepTerms.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/buttons/button-outline.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

import 'widgets/StepHomeserver.dart';
import 'widgets/StepPassword.dart';
import 'widgets/StepUsername.dart';

final Duration nextAnimationDuration = Duration(
  milliseconds: Values.animationDurationDefault,
);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> with Lifecycle<SignupScreen> {
  final sectionsPassword = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
  ];

  int currentStep = 0;
  bool validStep = false;
  bool onboarding = false;
  PageController? pageController;

  List<Widget> sections = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
    CaptchaStep(),
    TermsStep(),
    EmailStep(),
  ];

  SignupScreenState();

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: true,
      viewportFraction: 1.5,
    );
  }

  ///
  /// Update Flows (Signup)
  ///
  /// Update the stages and overall flow of signup
  /// based on the requirements of the homeserver selected
  ///
  onUpdateFlows(_Props props) {
    final signupTypes = props.homeserver.signupTypes;

    if (props.isPasswordLoginAvailable) {
      setState(() {
        sections = [...sectionsPassword];
      });
    }

    if (props.isSSOLoginAvailable && !props.isPasswordLoginAvailable) {
      setState(() {
        sections = [HomeserverStep()];
      });
    }

    final sectionsNew = List<Widget>.from(sections);

    for (final stage in signupTypes) {
      var stageNew;

      switch (stage) {
        case MatrixAuthTypes.EMAIL:
          stageNew = EmailStep();
          break;
        case MatrixAuthTypes.RECAPTCHA:
          stageNew = CaptchaStep();
          break;
        case MatrixAuthTypes.TERMS:
          stageNew = TermsStep();
          break;
        default:
          break;
      }

      if (!sectionsNew.contains(stageNew) && stageNew != null) {
        sectionsNew.add(stageNew);
      }
    }

    if (sectionsNew.length != sections.length) {
      setState(() {
        sections = sectionsNew;
      });
    }
  }

  @override
  onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final props = _Props.mapStateToProps(store);

    if (props.hostname != Values.homeserverDefault) {
      onUpdateFlows(props);
    }
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }

  onDidChange(_Props? oldProps, _Props props) {
    final ssoLoginChanged = props.isSSOLoginAvailable != oldProps?.isSSOLoginAvailable;
    final passwordLoginChanged =
        props.isPasswordLoginAvailable != oldProps?.isPasswordLoginAvailable;

    final signupTypesChanged = props.homeserver.signupTypes != oldProps?.homeserver.signupTypes;

    if (passwordLoginChanged || ssoLoginChanged || signupTypesChanged) {
      onUpdateFlows(props);
    }
  }

  onBackStep(BuildContext context) {
    if (currentStep < 1) {
      return Navigator.pop(context, false);
    }

    setState(() {
      currentStep = currentStep - 1;
    });

    pageController!.animateToPage(
      currentStep,
      duration: Duration(milliseconds: 275),
      curve: Curves.easeInOut,
    );
  }

  onCheckStepValid(_Props props, PageController? controller) {
    final currentSection = sections[currentStep];

    switch (currentSection.runtimeType) {
      case HomeserverStep:
        return props.isHomeserverValid;
      case UsernameStep:
        return props.isUsernameValid && props.isUsernameAvailable && !props.loading;
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

  onNavigateNextPage(PageController? controller) {
    controller!.nextPage(
      duration: nextAnimationDuration,
      curve: Curves.ease,
    );
  }

  onCompleteStep(_Props props, PageController? controller, {bool usingSSO = false}) {
    final store = StoreProvider.of<AppState>(context);
    final currentSection = sections[currentStep];
    final lastStep = (sections.length - 1) == currentStep;

    switch (currentSection.runtimeType) {
      case HomeserverStep:
        return () async {
          bool valid = true;

          if (props.hostname != props.homeserver.hostname) {
            valid = await props.onSelectHomeserver(props.hostname);
          }

          final homeserver = store.state.authStore.homeserver;
          if (homeserver.signupTypes.isEmpty &&
              !homeserver.loginTypes.contains(MatrixAuthTypes.SSO)) {
            store.dispatch(addInfo(
              origin: 'selectHomeserver',
              message: 'No new signups allowed on this server, try another if creating an account',
            ));
          }

          if (props.homeserver.loginTypes.contains(MatrixAuthTypes.SSO) && usingSSO) {
            valid = false; // don't do anything else
            await props.onLoginSSO();
          }

          if (valid) {
            props.onClearCompleted();
            onNavigateNextPage(controller);
          }
        };
      case UsernameStep:
        return () {
          onNavigateNextPage(controller);
        };
      case PasswordStep:
        return () async {
          final result = await props.onCreateUser(enableErrors: lastStep);

          // If signup is completed here, just wait for auth redirect
          if (result) {
            return;
          }

          return onNavigateNextPage(controller);
        };
      case CaptchaStep:
        return () async {
          bool? result = false;
          if (!props.completed.contains(MatrixAuthTypes.RECAPTCHA)) {
            result = await props.onCreateUser(enableErrors: lastStep);
          }
          if (!result!) {
            onNavigateNextPage(controller);
          }
        };
      case TermsStep:
        return () async {
          bool? result = false;
          if (!props.completed.contains(MatrixAuthTypes.TERMS)) {
            result = await props.onCreateUser(enableErrors: lastStep);
          }
          if (!result!) {
            return onNavigateNextPage(controller);
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
              return Navigator.pushNamed(context, Routes.verification);
            }

            // or continue if not the last step
            onNavigateNextPage(controller);
          }
        };
      default:
        return null;
    }
  }

  buildButtonString(_Props props) {
    if (currentStep == sections.length - 1) {
      return Strings.buttonFinish;
    }

    return Strings.buttonNext;
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        onWillChange:
            onDidChange, // NOTE: bug / issue where onDidChange doesn't show correct oldProps
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              systemOverlayStyle: computeSystemUIColor(context),
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
                  width: width,
                  height: height,
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 6,
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
                                    onboarding = index != 0 && index != sections.length - 1;
                                  });
                                },
                                children: sections,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 0,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.end,
                          direction: Axis.vertical,
                          children: <Widget>[
                            Visibility(
                              visible:
                                  !(!props.isPasswordLoginAvailable && props.isSSOLoginAvailable),
                              child: Container(
                                padding: const EdgeInsets.only(top: 12, bottom: 12),
                                child: ButtonSolid(
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
                              ),
                            ),
                            Visibility(
                              visible: props.isSSOLoginAvailable && currentStep == 0,
                              child: Container(
                                padding: const EdgeInsets.only(top: 12, bottom: 12),
                                child: props.isPasswordLoginAvailable
                                    ? ButtonOutline(
                                        text: Strings.buttonLoginSSO,
                                        disabled: props.loading,
                                        onPressed: onCompleteStep(
                                          props,
                                          pageController,
                                          usingSSO: true,
                                        ),
                                      )
                                    : ButtonSolid(
                                        text: Strings.buttonLoginSSO,
                                        disabled: props.loading,
                                        onPressed: onCompleteStep(
                                          props,
                                          pageController,
                                          usingSSO: true,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 0,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.center,
                          direction: Axis.vertical,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 12),
                              constraints: BoxConstraints(
                                minHeight: Dimensions.buttonHeightMin,
                              ),
                              child: Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SmoothPageIndicator(
                                    controller: pageController!,
                                    count: sections.length,
                                    effect: WormEffect(
                                      spacing: 16,
                                      dotHeight: 12,
                                      dotWidth: 12,
                                      activeDotColor: Theme.of(context).primaryColor,
                                    ),
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
  final bool isSSOLoginAvailable;
  final bool isPasswordLoginAvailable;
  final bool isSignupAvailable;

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

  final Function onLoginSSO;
  final Function onCreateUser;
  final Function onSubmitEmail;
  final Function onResetCredential;
  final Function onSelectHomeserver;
  final Function onClearCompleted;

  const _Props({
    required this.user,
    required this.hostname,
    required this.homeserver,
    required this.isHomeserverValid,
    required this.isPasswordLoginAvailable,
    required this.isSSOLoginAvailable,
    required this.isSignupAvailable,
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
    required this.completed,
    required this.onLoginSSO,
    required this.onCreateUser,
    required this.onSubmitEmail,
    required this.onResetCredential,
    required this.onSelectHomeserver,
    required this.onClearCompleted,
  });

  @override
  List<Object> get props => [
        user,
        hostname,
        homeserver,
        isHomeserverValid,
        isSSOLoginAvailable,
        isPasswordLoginAvailable,
        isSignupAvailable,
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
        verificationNeeded,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
      user: store.state.authStore.user,
      completed: store.state.authStore.completed,
      hostname: store.state.authStore.hostname,
      homeserver: store.state.authStore.homeserver,
      isHomeserverValid: store.state.authStore.homeserver.valid && !store.state.authStore.loading,
      isSSOLoginAvailable: selectSSOEnabled(store.state),
      isPasswordLoginAvailable: selectPasswordEnabled(store.state),
      isSignupAvailable: selectSignupClosed(store.state),
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
      onClearCompleted: () async {
        store.dispatch(setUsername(username: ''));
        store.dispatch(setPassword(password: ''));
      });
}

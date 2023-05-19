import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syphon/domain/alerts/actions.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/domain/auth/homeserver/model.dart';
import 'package:syphon/domain/auth/selectors.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/theme-settings/selectors.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/hooks.dart';
import 'package:syphon/global/libraries/matrix/auth/types.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/intro/signup/widgets/StepCaptcha.dart';
import 'package:syphon/views/intro/signup/widgets/StepEmail.dart';
import 'package:syphon/views/intro/signup/widgets/StepTerms.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/buttons/button-outline.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';

import 'widgets/StepHomeserver.dart';
import 'widgets/StepPassword.dart';
import 'widgets/StepUsername.dart';

final Duration nextAnimationDuration = Duration(
  milliseconds: Values.animationDurationDefault,
);

final sectionsPassword = [
  HomeserverStep(),
  UsernameStep(),
  PasswordStep(),
];

class SignupScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();
    final Size(:height, :width) = useDimensions(context);

    final pageController = usePageController(viewportFraction: 1.5);

    final (currentStep, setCurrentStep) = useStateful<int>(0);

    final (sections, setSections) = useStateful<List<Widget>>([
      HomeserverStep(),
      UsernameStep(),
      PasswordStep(),
      CaptchaStep(),
      TermsStep(),
      EmailStep(),
    ]);

    final hostname = useSelector<AppState, String>((state) => state.authStore.hostname, 'matrix.org');
    final homeserver = useSelector<AppState, Homeserver>(
        (state) => state.authStore.homeserver, Homeserver(hostname: hostname));

    final user = useSelector<AppState, User>((state) => state.authStore.user, User());
    final completed = useSelector<AppState, List<String>>((state) => state.authStore.completed, const []);

    final loading = useSelector<AppState, bool>((state) => state.authStore.loading, false);
    final captcha = useSelectorUnsafe<AppState, bool>((state) => state.authStore.captcha);
    final creating = useSelector<AppState, bool>((state) => state.authStore.creating, false);
    final agreement = useSelectorUnsafe<AppState, bool>((state) => state.authStore.agreement);

    // Validity Checks
    final isSSOLoginAvailable = useSelector<AppState, bool>(
      (state) => selectSSOEnabled(state),
      false,
    );
    final isPasswordLoginAvailable = useSelector<AppState, bool>(
      (state) => selectPasswordEnabled(state),
      false,
    );
    final isHomeserverValid = useSelector<AppState, bool>(
      (state) => state.authStore.homeserver.valid && !state.authStore.loading,
      false,
    );
    final isUsernameValid = useSelector<AppState, bool>(
      (state) => state.authStore.isUsernameValid,
      false,
    );
    final isUsernameAvailable = useSelector<AppState, bool>(
      (state) => state.authStore.isUsernameAvailable,
      false,
    );
    final isPasswordValid = useSelector<AppState, bool>(
      (state) => state.authStore.isPasswordValid,
      false,
    );
    final isEmailValid = useSelector<AppState, bool>(
      (state) => state.authStore.isEmailValid,
      false,
    );

    ///
    /// Update Flows (Signup)
    ///
    /// Update the stages and overall flow of signup
    /// based on the requirements of the homeserver selected
    ///
    onUpdateFlows() {
      final Homeserver(:signupTypes) = homeserver;

      if (isPasswordLoginAvailable) {
        setSections([...sectionsPassword]);
      } else if (isSSOLoginAvailable) {
        setSections([HomeserverStep()]);
      }

      var sectionsNew = [...sections];

      for (final stage in signupTypes) {
        switch (stage) {
          case MatrixAuthTypes.EMAIL:
            sectionsNew = {...sectionsNew, EmailStep()}.toList();
            break;
          case MatrixAuthTypes.RECAPTCHA:
            sectionsNew = {...sectionsNew, CaptchaStep()}.toList();
            break;
          case MatrixAuthTypes.TERMS:
            sectionsNew = {...sectionsNew, TermsStep()}.toList();
            break;
          default:
            break;
        }
      }

      if (sectionsNew.length != sections.length) {
        setSections(sectionsNew);
      }
    }

    useEffect(() {
      if (hostname != Values.homeserverDefault) {
        onUpdateFlows();
      }
    }, []);

    useEffect(() {
      onUpdateFlows();
    }, [isPasswordLoginAvailable, isSSOLoginAvailable, homeserver.signupTypes]);

    onSubmitEmail() async {
      return await dispatch(submitEmail());
    }

    onResetCredential() async {
      await dispatch(updateCredential(type: MatrixAuthTypes.DUMMY));
    }

    onLoginSSO() async {
      await dispatch(loginUserSSO());
    }

    onCreateUser({bool enableErrors = false}) async {
      return await dispatch(createUser(enableErrors: enableErrors));
    }

    onSelectHomeserver(String hostname) async {
      return await dispatch(selectHomeserver(hostname: hostname));
    }

    onClearCompleted() async {
      dispatch(setUsername(username: ''));
      dispatch(setPassword(password: ''));
    }

    onBackStep(BuildContext context) {
      if (currentStep < 1) {
        return Navigator.pop(context, false);
      }

      setCurrentStep(currentStep - 1);

      pageController.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 275),
        curve: Curves.easeInOut,
      );
    }

    bool onCheckStepValid() {
      final currentSection = sections[currentStep];

      switch (currentSection.runtimeType) {
        case HomeserverStep:
          return isHomeserverValid;
        case UsernameStep:
          return isUsernameValid && isUsernameAvailable && !loading;
        case PasswordStep:
          return isPasswordValid;
        case EmailStep:
          return isEmailValid;
        case CaptchaStep:
          return captcha ?? false;
        case TermsStep:
          return agreement ?? false;
        default:
          return false;
      }
    }

    onNavigateNextPage() {
      pageController.nextPage(
        duration: nextAnimationDuration,
        curve: Curves.ease,
      );
    }

    onCompleteStep({bool usingSSO = false}) {
      final store = StoreProvider.of<AppState>(context);
      final currentSection = sections[currentStep];
      final lastStep = (sections.length - 1) == currentStep;

      switch (currentSection.runtimeType) {
        case HomeserverStep:
          return () async {
            bool valid = true;

            if (hostname != homeserver.hostname) {
              valid = await onSelectHomeserver(hostname);
            }

            if (homeserver.signupTypes.isEmpty && !homeserver.loginTypes.contains(MatrixAuthTypes.SSO)) {
              store.dispatch(addInfo(
                origin: 'selectHomeserver',
                message: 'No new signups allowed on this server, try another if creating an account',
              ));
            }

            if (homeserver.loginTypes.contains(MatrixAuthTypes.SSO) && usingSSO) {
              valid = false; // don't do anything else
              await onLoginSSO();
            }

            if (valid) {
              onClearCompleted();
              onNavigateNextPage();
            }
          };
        case UsernameStep:
          return () {
            onNavigateNextPage();
          };
        case PasswordStep:
          return () async {
            final result = await onCreateUser(enableErrors: lastStep);

            // If signup is completed here, just wait for auth redirect
            if (result) return;

            return onNavigateNextPage();
          };
        case CaptchaStep:
          return () async {
            bool? result = false;
            if (!completed.contains(MatrixAuthTypes.RECAPTCHA)) {
              result = await onCreateUser(enableErrors: lastStep);
            }
            if (!result!) {
              onNavigateNextPage();
            }
          };
        case TermsStep:
          return () async {
            bool? result = false;
            if (!completed.contains(MatrixAuthTypes.TERMS)) {
              result = await onCreateUser(enableErrors: lastStep);
            }

            if (!result!) {
              return onNavigateNextPage();
            }

            // If the user has a completed auth flow for matrix.org, reset to
            // proper auth type to attempt a real account creation
            // for matrix and try again
            if (result && user.accessToken == null) {
              await onResetCredential();
              onCreateUser();
            }
          };
        case EmailStep:
          return () async {
            bool? result = false;
            final validEmail = await onSubmitEmail();

            // don't run anything if email is already in use
            if (!validEmail) {
              return false;
            }

            // try using email signup without verification
            if (!completed.contains(MatrixAuthTypes.EMAIL)) {
              result = await onCreateUser(enableErrors: lastStep);
            }

            // otherwise, send to the verification holding page
            if (!result!) {
              if (lastStep) {
                return Navigator.pushNamed(context, Routes.verification);
              }

              // or continue if not the last step
              onNavigateNextPage();
            }
          };
        default:
          return null;
      }
    }

    buildButtonString() {
      if (currentStep == sections.length - 1) {
        return Strings.buttonFinish;
      }

      return Strings.buttonNext;
    }

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
                            setCurrentStep(index);
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
                        visible: !(!isPasswordLoginAvailable && isSSOLoginAvailable),
                        child: Container(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: ButtonSolid(
                            text: buildButtonString(),
                            loading: creating || loading,
                            disabled: creating || !onCheckStepValid(),
                            onPressed: onCompleteStep(),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: isSSOLoginAvailable && currentStep == 0,
                        child: Container(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: isPasswordLoginAvailable
                              ? ButtonOutline(
                                  text: Strings.buttonLoginSSO,
                                  disabled: loading,
                                  onPressed: onCompleteStep(usingSSO: true),
                                )
                              : ButtonSolid(
                                  text: Strings.buttonLoginSSO,
                                  disabled: loading,
                                  onPressed: onCompleteStep(usingSSO: true),
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
  }
}

import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/intro/login/forgot/widgets/PageEmailVerify.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/dialogs/dialog-explaination.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ForgotPasswordState createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPasswordScreen> {
  int sendAttempt = 1;
  bool loading = false;
  bool showConfirmation = false;
  PageController? pageController;

  var sections = [
    EmailVerifyStep(),
  ];

  ForgotPasswordState();

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );
  }

  onShowConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => DialogExplaination(
        title: Strings.titleConfirmEmail,
        content: Strings.contentConfirmPasswordReset,
        onConfirm: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  onVerificationConfirmed() {
    Navigator.pushNamed(context, Routes.reset);
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

          return Scaffold(
            appBar: AppBar(
              systemOverlayStyle: computeSystemUIColor(context),
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ),
            extendBodyBehindAppBar: true,
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
                        flex: 9,
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
                                maxHeight: Dimensions.heightMax * 0.5,
                              ),
                              child: PageView(
                                pageSnapping: true,
                                allowImplicitScrolling: false,
                                controller: pageController,
                                physics: NeverScrollableScrollPhysics(),
                                children: sections,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.center,
                          direction: Axis.vertical,
                          children: <Widget>[
                            Container(
                              height: Dimensions.inputHeight,
                              constraints: BoxConstraints(
                                minWidth: Dimensions.buttonWidthMin,
                              ),
                              child: Stack(
                                children: [
                                  Visibility(
                                    visible: !showConfirmation,
                                    child: ButtonSolid(
                                      text: Strings.buttonSendVerification,
                                      loading: loading,
                                      disabled: !props.isEmailValid || !props.isHomeserverValid,
                                      onPressed: () async {
                                        setState(() {
                                          loading = true;
                                        });

                                        final result = await props.onSendVerification(sendAttempt);

                                        if (result) {
                                          onShowConfirmDialog();
                                          setState(() {
                                            sendAttempt += 1;
                                            showConfirmation = true;
                                          });
                                        }

                                        setState(() {
                                          loading = false;
                                        });
                                      },
                                    ),
                                  ),
                                  Visibility(
                                    visible: showConfirmation,
                                    child: ButtonSolid(
                                      text: Strings.buttonConfirmVerification,
                                      loading: props.loading || loading,
                                      disabled: !props.isEmailValid,
                                      onPressed: () async {
                                        setState(() {
                                          loading = true;
                                        });

                                        final result = await props.onConfirmVerification();

                                        if (result) {
                                          onVerificationConfirmed();
                                        } else {
                                          onShowConfirmDialog();
                                        }

                                        setState(() {
                                          loading = false;
                                        });
                                      },
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
  final bool loading;
  final bool isEmailValid;
  final bool isHomeserverValid;
  final Map interactiveAuths;
  final Function onSendVerification;
  final Function onConfirmVerification;

  const _Props({
    required this.loading,
    required this.isEmailValid,
    required this.isHomeserverValid,
    required this.interactiveAuths,
    required this.onSendVerification,
    required this.onConfirmVerification,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        isEmailValid: store.state.authStore.isEmailValid,
        isHomeserverValid: store.state.authStore.isHomeserverValid,
        interactiveAuths: store.state.authStore.interactiveAuths,
        onConfirmVerification: () async {
          return true;
          // TODO: find a way to check if they've clicked the link
          // without invalidating the token, sending a blank password
          // doesn't work
          // return await store.dispatch(
          //   checkPasswordResetVerification(sendAttempt: 0),
          // );
        },
        onSendVerification: (int sendAttempt) async {
          return await store.dispatch(
            sendPasswordResetEmail(sendAttempt: sendAttempt),
          );
        },
      );

  @override
  List<Object> get props => [
        loading,
        isEmailValid,
        interactiveAuths,
      ];
}

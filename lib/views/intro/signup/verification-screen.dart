import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/widgets/buttons/button-solid.dart';
import 'package:syphon/views/widgets/buttons/button-text.dart';
import 'package:syphon/views/widgets/dialogs/dialog-explaination.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> with WidgetsBindingObserver {
  late bool sending;
  bool? success;

  late int sendAttempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    setState(() {
      sending = false;
      sendAttempt = 1;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    final store = StoreProvider.of<AppState>(context);
    final props = _Props.mapStateToProps(store);

    switch (state) {
      case AppLifecycleState.resumed:
        if (success == null || !success!) {
          final result = await props.onCreateUser(enableErrors: true);
          setState(() {
            success = result;
          });
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;

          return Scaffold(
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                child: Container(
                  height: height,
                  width: width,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: height * 0.01,
                    ),
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: Container(
                            width: Dimensions.contentWidth(context),
                            constraints: BoxConstraints(
                              maxHeight: Dimensions.mediaSizeMax,
                              maxWidth: Dimensions.mediaSizeMax,
                            ),
                            child: SvgPicture.asset(
                              Assets.heroSignupVerificationView,
                              semanticsLabel:
                                  'Letter in envelop floating upward with attached balloons',
                            ),
                          ),
                        ),
                        Flexible(
                          child: Flex(
                            direction: Axis.vertical,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(bottom: 8, top: 8),
                                child: Text(
                                  'Check your email and click the verification\nlink to finish account creation.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                              Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      'Verify your email address',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline5,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) => DialogExplaination(
                                            title: Strings.titleDialogSignupEmailVerification,
                                            content: Strings.contentEmailVerification,
                                            onConfirm: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 20,
                                        width: 20,
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Theme.of(context).colorScheme.secondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Flex(
                            mainAxisAlignment: MainAxisAlignment.center,
                            direction: Axis.vertical,
                            children: <Widget>[
                              Container(
                                width: Dimensions.contentWidth(context),
                                margin: EdgeInsets.only(top: height * 0.01),
                                height: Dimensions.inputHeight,
                                constraints: BoxConstraints(
                                  minWidth: Dimensions.buttonWidthMin,
                                  maxWidth: Dimensions.buttonWidthMax,
                                ),
                                child: ButtonSolid(
                                  text: 'check verification',
                                  loading: sending || props.loading,
                                  disabled: sending || props.loading,
                                  onPressed: () async {
                                    final result = await props.onCreateUser(enableErrors: true);
                                    setState(() {
                                      success = result;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                width: Dimensions.contentWidth(context),
                                margin: EdgeInsets.only(top: height * 0.01),
                                height: Dimensions.inputHeight,
                                constraints: BoxConstraints(
                                  minWidth: Dimensions.buttonWidthMin,
                                  maxWidth: Dimensions.buttonWidthMax,
                                ),
                                child: ButtonText(
                                  text: 'resend email',
                                  disabled: sending || props.loading,
                                  onPressed: () {
                                    props.onResendVerification(
                                      sendAttempt: sendAttempt + 1,
                                    );
                                    setState(() {
                                      sendAttempt = sendAttempt + 1;
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
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final bool verification;

  final Function onCreateUser;
  final Function onResendVerification;

  const _Props({
    required this.loading,
    required this.verification,
    required this.onCreateUser,
    required this.onResendVerification,
  });

  @override
  List<Object> get props => [
        loading,
        verification,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.authStore.loading,
        verification: store.state.authStore.verificationNeeded,
        onResendVerification: ({int? sendAttempt}) async {
          return await store.dispatch(submitEmail(sendAttempt: sendAttempt));
        },
        onCreateUser: ({bool enableErrors = false}) async {
          return await store.dispatch(createUser(enableErrors: enableErrors));
        },
      );
}

import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/dialogs/dialog-explaination.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

// Store

// Styling

class EmailVerifyStep extends StatefulWidget {
  const EmailVerifyStep({Key? key}) : super(key: key);

  @override
  EmailStepState createState() => EmailStepState();
}

class EmailStepState extends State<EmailVerifyStep> {
  Timer? typingTimeout;
  final emailController = TextEditingController();
  final homeserverController = TextEditingController();

  EmailStepState();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    emailController.text = store.state.authStore.email;
    homeserverController.text = store.state.authStore.homeserver.hostname!;
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        final double height = MediaQuery.of(context).size.height;

        Color suffixBackgroundColor = Colors.grey;
        Widget suffixWidgetHomeserver = CircularProgressIndicator(
          strokeWidth: Dimensions.strokeWidthDefault,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        );

        Widget suffixWidgetEmail = CircularProgressIndicator(
          strokeWidth: Dimensions.strokeWidthDefault,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        );

        if (props.isEmailValid) {
          suffixWidgetEmail = Icon(
            Icons.check,
            color: Colors.white,
          );
          suffixBackgroundColor = Theme.of(context).primaryColor;
        }

        if (!props.loading && typingTimeout == null) {
          if (props.isHomeserverValid) {
            suffixWidgetHomeserver = Icon(
              Icons.check,
              color: Colors.white,
            );
            suffixBackgroundColor = Theme.of(context).primaryColor;
          } else {
            suffixWidgetHomeserver = Icon(
              Icons.close,
              color: Colors.white,
            );
            suffixBackgroundColor = Colors.red;
          }
        }

        return Container(
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
                    maxHeight: Dimensions.mediaSizeMax * 0.5,
                    maxWidth: Dimensions.mediaSizeMax * 0.5,
                  ),
                  child: SvgPicture.asset(
                    Assets.heroResetPasswordEmail,
                    semanticsLabel: Strings.semanticsImagePasswordReset,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 32),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 24,
                            ),
                            child: Text(
                              'Enter both your email\n and homeserver',
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
                                    title: Strings.titleEmailRequirement,
                                    content: Strings.contentForgotEmailVerification,
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
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(bottom: 16, top: 8),
                  width: Dimensions.contentWidthWide(context),
                  height: Dimensions.inputHeight,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: TextFieldSecure(
                    label: 'Homeserver',
                    hint: Values.homeserverDefault,
                    disableSpacing: true,
                    disabled: props.session,
                    valid: props.isHomeserverValid,
                    controller: homeserverController,
                    onSubmitted: (hostname) {
                      FocusScope.of(context).unfocus();
                      // Set new username
                      props.onSelectHomeserver(hostname);
                    },
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      // Set new username
                      props.onSelectHomeserver();
                    },
                    onChanged: (hostname) {
                      // Set new username
                      // clear current timeout if something changed
                      if (typingTimeout != null) {
                        typingTimeout!.cancel();
                        setState(() {
                          typingTimeout = null;
                        });
                      }

                      // Run check after 1 second of no typing
                      typingTimeout = Timer(
                        Duration(milliseconds: 1000),
                        () {
                          props.onSelectHomeserver(hostname);

                          setState(() {
                            typingTimeout = null;
                          });
                        },
                      );
                    },
                    suffix: Visibility(
                      visible: props.isHomeserverValid,
                      child: Container(
                        width: 12,
                        height: 12,
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: suffixBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          child: suffixWidgetHomeserver,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Container(
                  width: Dimensions.contentWidthWide(context),
                  height: Dimensions.inputHeight,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: TextFieldSecure(
                    label: 'Email',
                    disableSpacing: true,
                    disabled: props.session,
                    valid: props.isEmailValid,
                    controller: emailController,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (email) {
                      // Set new username
                      props.onSetEmail(email);
                    },
                    suffix: Visibility(
                      visible: props.isEmailValid,
                      child: Container(
                        width: 12,
                        height: 12,
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: suffixBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          child: suffixWidgetEmail,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      });
}

class _Props extends Equatable {
  final String email;
  final String hostname;
  final bool session;
  final bool loading;
  final bool isEmailValid;
  final bool isHomeserverValid;

  final Function onSetEmail;
  final Function onSetHomeserver;
  final Function onSelectHomeserver;

  const _Props({
    required this.email,
    required this.hostname,
    required this.session,
    required this.loading,
    required this.isEmailValid,
    required this.isHomeserverValid,
    required this.onSetEmail,
    required this.onSetHomeserver,
    required this.onSelectHomeserver,
  });

  @override
  List<Object> get props => [
        email,
        loading,
        isEmailValid,
        isHomeserverValid,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        email: store.state.authStore.email,
        hostname: store.state.authStore.hostname,
        loading: store.state.authStore.loading,
        isEmailValid: store.state.authStore.isEmailValid,
        isHomeserverValid: store.state.authStore.homeserver.valid,
        session: store.state.authStore.authSession != null &&
            store.state.authStore.authSession!.isNotEmpty,
        onSetEmail: (email) {
          return store.dispatch(setEmail(email: email));
        },
        onSetHomeserver: ({String? hostname}) {
          return store.dispatch(setHostname(hostname: hostname));
        },
        onSelectHomeserver: (String? homeserver) async {
          final hostname = homeserver ?? store.state.authStore.hostname;
          final urlRegex = RegExp(Values.urlRegex, caseSensitive: false);

          if (urlRegex.hasMatch('https://$hostname')) {
            await store.dispatch(selectHomeserver(hostname: hostname));
          }
        },
      );
}

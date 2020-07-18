import 'dart:async';

import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:syphon/store/index.dart';

// Styling
import 'package:syphon/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

class EmailStep extends StatefulWidget {
  const EmailStep({Key key}) : super(key: key);

  EmailStepState createState() => EmailStepState();
}

class EmailStepState extends State<EmailStep> {
  EmailStepState({Key key});

  Timer typingTimeout;
  final emailController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    emailController.text = trimmedUserId(
      userId: store.state.authStore.username,
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        double height = MediaQuery.of(context).size.height;

        Color suffixBackgroundColor = Colors.grey;
        Widget suffixWidget = CircularProgressIndicator(
          strokeWidth: Dimensions.defaultStrokeWidth,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        );

        if (!props.loading && this.typingTimeout == null) {
          if (props.isEmailValid) {
            suffixWidget = Icon(
              Icons.check,
              color: Colors.white,
            );
            suffixBackgroundColor = Theme.of(context).primaryColor;
          } else {
            suffixWidget = Icon(
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
                    maxHeight: Dimensions.mediaSizeMax,
                    maxWidth: Dimensions.mediaSizeMax,
                  ),
                  child: SvgPicture.asset(
                    Assets.heroSignupEmail,
                    semanticsLabel: 'Person resting on I.D. card',
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
                      padding: EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        'This homeserver requires an email\n for account creation.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                    Container(
                      child: Stack(
                        overflow: Overflow.visible,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 24,
                            ),
                            child: Text(
                              'Enter an email address',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                debugPrint(
                                  'TODO: navigate to captcha explination',
                                );
                              },
                              child: Container(
                                height: 20,
                                width: 20,
                                child: Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).accentColor,
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
                  width: Dimensions.contentWidthWide(context),
                  height: Dimensions.inputHeight,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: TextFieldSecure(
                    label: "Email",
                    disableSpacing: true,
                    valid: props.isEmailValid,
                    controller: emailController,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                    onEditingComplete: () {
                      props.onCheckEmailAvailable();
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (email) {
                      // // Trim new username
                      emailController.value = TextEditingValue(
                        text: email,
                        selection: TextSelection.fromPosition(
                          TextPosition(
                            offset: email.length,
                          ),
                        ),
                      );

                      // Set new username
                      props.onSetEmail(email: email);

                      // clear current timeout if something changed
                      if (typingTimeout != null) {
                        typingTimeout.cancel();
                        this.setState(() {
                          typingTimeout = null;
                        });
                      }

                      // Run check after 1 second of no typing
                      typingTimeout = Timer(
                        Duration(milliseconds: 1000),
                        () {
                          props.onCheckEmailAvailable();
                          this.setState(() {
                            typingTimeout = null;
                          });
                        },
                      );
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
                          padding: EdgeInsets.all((6)),
                          child: suffixWidget,
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
  final bool loading;
  final String email;
  final bool isEmailValid;

  final Function onSetEmail;
  final Function onCheckEmailAvailable;

  _Props({
    @required this.email,
    @required this.isEmailValid,
    @required this.loading,
    @required this.onSetEmail,
    @required this.onCheckEmailAvailable,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        email: store.state.authStore.email,
        isEmailValid: store.state.authStore.isEmailValid,
        loading: store.state.authStore.loading,
        onSetEmail: ({String email}) {
          if (email != null) {
            return store.dispatch(setEmail(email: email));
          }

          return store.dispatch(setEmail(email: store.state.authStore.email));
        },
        onCheckEmailAvailable: () {
          // store.dispatch(checkUsernameAvailability());
        },
      );

  @override
  List<Object> get props => [
        email,
        loading,
        isEmailValid,
      ];
}

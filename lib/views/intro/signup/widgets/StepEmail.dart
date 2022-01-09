import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/dialogs/dialog-explaination.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

// Store

// Styling

class EmailStep extends StatefulWidget {
  const EmailStep({Key? key}) : super(key: key);

  @override
  EmailStepState createState() => EmailStepState();
}

class EmailStepState extends State<EmailStep> {
  EmailStepState();

  Timer? typingTimeout;
  final emailController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    emailController.text = store.state.authStore.email;
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        final double height = MediaQuery.of(context).size.height;

        Color suffixBackgroundColor = Colors.grey;
        Widget suffixWidget = CircularProgressIndicator(
          strokeWidth: Dimensions.strokeWidthDefault,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        );

        if (!props.loading && typingTimeout == null) {
          if (props.isEmailValid && props.isEmailAvailable) {
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
                    semanticsLabel: 'Person resting on checked letter',
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
                    Stack(
                      clipBehavior: Clip.none,
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
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => DialogExplaination(
                                  title: Strings.titleEmailRequirement,
                                  content: Strings.contentEmailRequirement,
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
                    Visibility(
                      visible: !props.isEmailAvailable,
                      child: Container(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          '* Email is already in use by another user',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption!.copyWith(
                                color: Colors.red,
                              ),
                        ),
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
                    label: Strings.labelEmail,
                    disableSpacing: true,
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
                      props.onSetEmail(email: email);

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
                          setState(() {
                            typingTimeout = null;
                          });
                        },
                      );
                    },
                    suffix: Visibility(
                      visible: props.isEmailValid || !props.isEmailAvailable,
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
  final bool isEmailAvailable;

  final Function onSetEmail;

  const _Props({
    required this.email,
    required this.isEmailValid,
    required this.isEmailAvailable,
    required this.loading,
    required this.onSetEmail,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        email: store.state.authStore.email,
        isEmailValid: store.state.authStore.isEmailValid,
        isEmailAvailable: store.state.authStore.isEmailAvailable,
        loading: store.state.authStore.loading,
        onSetEmail: ({String? email}) {
          if (email != null) {
            store.dispatch(updateCredential(
              type: MatrixAuthTypes.EMAIL,
              value: email,
            ));
            return store.dispatch(setEmail(email: email));
          }

          return store.dispatch(setEmail(email: store.state.authStore.email));
        },
      );

  @override
  List<Object> get props => [
        email,
        loading,
        isEmailValid,
        isEmailAvailable,
      ];
}

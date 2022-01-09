import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';

class PasswordUpdateStep extends StatefulWidget {
  const PasswordUpdateStep({Key? key}) : super(key: key);

  @override
  PasswordUpdateStepState createState() => PasswordUpdateStepState();
}

class PasswordUpdateStepState extends State<PasswordUpdateStep> {
  PasswordUpdateStepState();

  bool visibility = false;
  FocusNode currentFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmFocusNode = FocusNode();

  final currentController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          return Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  flex: 4,
                  fit: FlexFit.tight,
                  child: Container(
                    width: width * 0.65,
                    padding: EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(
                      maxHeight: Dimensions.mediaSizeMax,
                      maxWidth: Dimensions.mediaSizeMax,
                    ),
                    child: SvgPicture.asset(
                      Assets.heroSignupPassword,
                      semanticsLabel: 'User thinking up a password in a swirl of wind',
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
                          Strings.contentPasswordRecommendation,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Update Password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Container(
                    width: width * 0.7,
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minWidth: Dimensions.inputWidthMin,
                      maxWidth: Dimensions.inputWidthMax,
                    ),
                    child: TextFieldSecure(
                      label: 'Current Password',
                      obscureText: false,
                      valid: props.isPasswordValid,
                      focusNode: currentFocusNode,
                      controller: currentController,
                      onChanged: (text) {
                        props.onChangeCurrentPassword(text);
                      },
                      onSubmitted: (String value) {
                        FocusScope.of(context).requestFocus(confirmFocusNode);
                      },
                      onEditingComplete: () {
                        props.onChangeCurrentPassword(props.password);
                        passwordFocusNode.unfocus();
                      },
                    ),
                  ),
                ),
                Container(
                    padding: EdgeInsets.symmetric(
                  vertical: 8,
                )),
                Flexible(
                  flex: 1,
                  child: Container(
                    width: width * 0.7,
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minWidth: Dimensions.inputWidthMin,
                      maxWidth: Dimensions.inputWidthMax,
                    ),
                    child: TextFieldSecure(
                      label: 'New Password',
                      focusNode: passwordFocusNode,
                      controller: passwordController,
                      valid: props.isPasswordValid,
                      obscureText: !visibility,
                      onChanged: (text) {
                        props.onChangePassword(text);
                      },
                      onSubmitted: (String value) {
                        FocusScope.of(context).requestFocus(confirmFocusNode);
                      },
                      onEditingComplete: () {
                        props.onChangePassword(props.password);
                        passwordFocusNode.unfocus();
                      },
                      suffix: GestureDetector(
                        onTap: () {
                          if (!passwordFocusNode.hasFocus) {
                            // Unfocus all focus nodes
                            passwordFocusNode.unfocus();

                            // Disable text field's focus node request
                            passwordFocusNode.canRequestFocus = false;
                          }

                          // Do your stuff
                          setState(() {
                            visibility = !visibility;
                          });

                          if (!passwordFocusNode.hasFocus) {
                            //Enable the text field's focus node request after some delay
                            Future.delayed(Duration(milliseconds: 100), () {
                              passwordFocusNode.canRequestFocus = true;
                            });
                          }
                        },
                        child: Icon(
                          visibility ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(padding: EdgeInsets.symmetric(vertical: 8)),
                Flexible(
                  flex: 1,
                  child: Container(
                    width: width * 0.7,
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minWidth: Dimensions.inputWidthMin,
                      maxWidth: Dimensions.inputWidthMax,
                    ),
                    child: TextFieldSecure(
                      label: 'Confirm New Password',
                      obscureText: true,
                      focusNode: confirmFocusNode,
                      controller: confirmController,
                      onChanged: (text) {
                        props.onChangePasswordConfirm(text);
                      },
                      onEditingComplete: () {
                        props.onChangePasswordConfirm(props.password);
                        confirmFocusNode.unfocus();
                      },
                      suffix: Visibility(
                        visible: props.isPasswordValid,
                        child: Container(
                          width: 12,
                          height: 12,
                          margin: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final String password;
  final String passwordCurrent;
  final String passwordConfirm;
  final bool isPasswordValid;

  final Function onChangePassword;
  final Function onChangePasswordConfirm;
  final Function onChangeCurrentPassword;

  const _Props({
    required this.password,
    required this.passwordCurrent,
    required this.passwordConfirm,
    required this.isPasswordValid,
    required this.onChangePassword,
    required this.onChangePasswordConfirm,
    required this.onChangeCurrentPassword,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        password: store.state.authStore.password,
        passwordCurrent: store.state.authStore.passwordCurrent,
        passwordConfirm: store.state.authStore.passwordConfirm,
        isPasswordValid: store.state.authStore.isPasswordValid,
        onChangePassword: (String text) {
          store.dispatch(setPassword(password: text));
        },
        onChangePasswordConfirm: (String text) {
          store.dispatch(setPasswordConfirm(password: text));
        },
        onChangeCurrentPassword: (String text) {
          store.dispatch(setPasswordCurrent(password: text));
        },
      );

  @override
  List<Object> get props => [
        password,
        passwordConfirm,
        isPasswordValid,
      ];
}

import 'dart:async';

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
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/input/text-field-secure.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({Key? key}) : super(key: key);

  @override
  UsernameStepState createState() => UsernameStepState();
}

class UsernameStepState extends State<UsernameStep> with Lifecycle<UsernameStep> {
  UsernameStepState();

  Timer? typingTimeout;
  final usernameController = TextEditingController();

  @override
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    usernameController.text = trimAlias(store.state.authStore.username);
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
          if (props.isUsernameAvailable) {
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
                  child: SvgPicture.asset(Assets.heroSignupUsername,
                      semanticsLabel: Strings.semanticsImageSignupUsername),
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      Strings.headerSignupUsername,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headline5,
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
                    label: props.isUsernameValid ? props.fullUserId : 'Username',
                    disableSpacing: true,
                    dirty: usernameController.text.length > 6,
                    valid: props.isUsernameValid,
                    controller: usernameController,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                    onEditingComplete: () {
                      props.onSetUsername();
                      props.onCheckUsernameAvailability();
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (username) {
                      // Set new username
                      props.onSetUsername(username: username);

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
                          props.onCheckUsernameAvailability();
                          setState(() {
                            typingTimeout = null;
                          });
                        },
                      );
                    },
                    suffix: Visibility(
                      visible: props.isUsernameValid,
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
  final String username;
  final String fullUserId;
  final bool isUsernameValid;
  final bool isUsernameAvailable;
  final bool loading;

  final Function onSetUsername;
  final Function onCheckUsernameAvailability;

  const _Props({
    required this.username,
    required this.fullUserId,
    required this.isUsernameValid,
    required this.isUsernameAvailable,
    required this.loading,
    required this.onSetUsername,
    required this.onCheckUsernameAvailability,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        username: store.state.authStore.username,
        fullUserId: formatAlias(
          resource: store.state.authStore.username,
          homeserver: store.state.authStore.hostname,
        ),
        isUsernameValid: store.state.authStore.isUsernameValid,
        isUsernameAvailable: store.state.authStore.isUsernameAvailable,
        loading: store.state.authStore.loading,
        onCheckUsernameAvailability: () {
          store.dispatch(checkUsernameAvailability());
        },
        onSetUsername: ({String? username}) {
          if (username != null) {
            store.dispatch(setUsername(username: username));
          } else {
            store.dispatch(
              setUsername(username: store.state.authStore.username),
            );
          }
        },
      );

  @override
  List<Object> get props => [
        username,
        fullUserId,
        isUsernameValid,
        isUsernameAvailable,
        loading,
      ];
}

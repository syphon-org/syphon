import 'dart:async';

import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:syphon/store/index.dart';

// Styling
import 'package:syphon/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syphon/global/dimensions.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({Key key}) : super(key: key);

  UsernameStepState createState() => UsernameStepState();
}

class UsernameStepState extends State<UsernameStep> {
  UsernameStepState({Key key});

  Timer typingTimeout;
  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    usernameController.text = trimmedUserId(
      userId: store.state.authStore.username,
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        double width = MediaQuery.of(context).size.width;
        double height = MediaQuery.of(context).size.height;

        Color suffixBackgroundColor = Colors.grey;
        Widget suffixWidget = CircularProgressIndicator(
          strokeWidth: Dimensions.defaultStrokeWidth,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        );

        if (!props.loading && this.typingTimeout == null) {
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
                  width: width * 0.75,
                  constraints: BoxConstraints(
                    maxHeight: Dimensions.mediaSizeMax,
                    maxWidth: Dimensions.mediaSizeMax,
                  ),
                  child: SvgPicture.asset(
                    Assets.heroSignupUsername,
                    semanticsLabel: 'Person resting on I.D. card',
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Create a username',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Container(
                  width: width * 0.8,
                  height: Dimensions.inputHeight,
                  constraints: BoxConstraints(
                    minWidth: Dimensions.inputWidthMin,
                    maxWidth: Dimensions.inputWidthMax,
                  ),
                  child: TextFormField(
                    keyboardAppearance: Brightness.dark,
                    cursorColor: Theme.of(context).primaryColor,
                    controller: usernameController,
                    onChanged: (username) {
                      // // Trim new username
                      final formattedUsername = username.trim();
                      usernameController.value = TextEditingValue(
                        text: formattedUsername,
                        selection: TextSelection.fromPosition(
                          TextPosition(
                            offset: formattedUsername.length,
                          ),
                        ),
                      );

                      // Set new username
                      props.onSetUsername(username: formattedUsername);

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
                          props.onCheckUsernameAvailability();
                          this.setState(() {
                            typingTimeout = null;
                          });
                        },
                      );
                    },
                    onEditingComplete: () {
                      props.onSetUsername();
                      props.onCheckUsernameAvailability();
                      FocusScope.of(context).unfocus();
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      labelText:
                          props.isUsernameValid ? props.fullUserId : "Username",
                      suffixIcon: Visibility(
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
                            padding: EdgeInsets.all((6)),
                            child: suffixWidget,
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

  _Props({
    @required this.username,
    @required this.fullUserId,
    @required this.isUsernameValid,
    @required this.isUsernameAvailable,
    @required this.loading,
    @required this.onSetUsername,
    @required this.onCheckUsernameAvailability,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        username: store.state.authStore.username,
        fullUserId: userAlias(
          username: store.state.authStore.username,
          homeserver: store.state.authStore.homeserver,
        ),
        isUsernameValid: store.state.authStore.isUsernameValid,
        isUsernameAvailable: store.state.authStore.isUsernameAvailable,
        loading: store.state.authStore.loading,
        onCheckUsernameAvailability: () {
          store.dispatch(checkUsernameAvailability());
        },
        onSetUsername: ({String username}) {
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

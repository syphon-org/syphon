import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/domain/user/selectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Domain
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/domain/index.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({Key key}) : super(key: key);

  UsernameStepState createState() => UsernameStepState();
}

class UsernameStepState extends State<UsernameStep> {
  UsernameStepState({Key key});

  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      runInitTasks();
    });
  }

  @protected
  void runInitTasks() {
    final store = StoreProvider.of<AppState>(context);
    usernameController.text = username(store.state);
  }

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, Store<AppState>>(
        converter: (Store<AppState> store) => store,
        builder: (context, store) => Container(
          child: Flex(
            direction: Axis.vertical,
            children: <Widget>[
              Flexible(
                flex: 3,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 256,
                    minWidth: 256,
                    maxHeight: 320,
                    maxWidth: 320,
                  ),
                  child: SvgPicture.asset(SIGNUP_USERNAME_GRAPHIC,
                      semanticsLabel: 'Person resting on I.D. card'),
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
                      style: Theme.of(context).textTheme.headline,
                    ),
                  ],
                ),
              ),
              Container(
                height: DEFAULT_INPUT_HEIGHT,
                margin: EdgeInsets.only(
                  top: 58,
                ),
                constraints: BoxConstraints(
                  minWidth: 200,
                  maxWidth: 320,
                ),
                child: TextField(
                  controller: usernameController,
                  onChanged: (username) {
                    // Trim new username
                    usernameController.value = TextEditingValue(
                      text: username.trim(),
                      selection: TextSelection.fromPosition(
                        TextPosition(
                          offset: username.trim().length,
                        ),
                      ),
                    );

                    // Set new username
                    store.dispatch(setUsername(username: username));
                  },
                  onEditingComplete: () {
                    store.dispatch(
                      setUsername(username: store.state.userStore.username),
                    );
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      labelText: store.state.userStore.username != null ||
                              store.state.userStore.username.length > 0
                          ? alias(store.state)
                          : "Username"),
                ),
              ),
            ],
          ),
        ),
      );
}

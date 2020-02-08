import 'package:Tether/domain/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Domain
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/model.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';

class PasswordStep extends StatefulWidget {
  const PasswordStep({Key key}) : super(key: key);

  PasswordStepState createState() => PasswordStepState();
}

class PasswordStepState extends State<PasswordStep> {
  PasswordStepState({Key key});

  final passwordController = TextEditingController();

  bool visibility = false;

  @override
  void initState() {
    super.initState();
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
                    minHeight: 220,
                    minWidth: 200,
                    maxWidth: 400,
                  ),
                  child: SvgPicture.asset(SIGNUP_PASSWORD_GRAPHIC,
                      semanticsLabel: 'User holding on to credentials'),
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Create a password',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline,
                      ),
                    ),
                    Text(
                        'Try thinking up 4 random words you\'ll\nremember easily',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subtitle1),
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
                  controller: passwordController,
                  obscureText: !visibility,
                  onChanged: (text) {
                    store.dispatch(
                        setPassword(password: text.replaceAll(' ', '')));
                  },
                  onEditingComplete: () {
                    store.dispatch(
                      setPassword(password: store.state.userStore.password),
                    );
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                        icon: Icon(
                          visibility ? Icons.visibility : Icons.visibility_off,
                        ),
                        tooltip: 'Show password in plaintext',
                        onPressed: () {
                          this.setState(() {
                            visibility = !visibility;
                          });
                        }),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(34.0)),
                    labelText: 'Password',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

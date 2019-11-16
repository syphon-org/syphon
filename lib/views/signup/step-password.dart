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
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        SizedBox(height: height * 0.1),
        Container(
          width: width * 0.7,
          height: DEFAULT_INPUT_HEIGHT,
          constraints:
              BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 240),
          child: SvgPicture.asset(SIGNUP_PASSWORD_GRAPHIC,
              semanticsLabel: 'User hidding behind a message'),
        ),
        SizedBox(height: 24),
        Text(
          'Create a password',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline,
        ),
        SizedBox(height: 24),
        Text('Try thinking up 4 random words you\'ll\nremember easily',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.subhead),
        SizedBox(height: height * 0.025),
        StoreConnector<AppState, Store<AppState>>(
            converter: (Store<AppState> store) => store,
            builder: (context, store) {
              return Container(
                width: width * 0.7,
                height: DEFAULT_INPUT_HEIGHT,
                margin: const EdgeInsets.all(10.0),
                constraints:
                    BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 45),
                child: TextField(
                  controller: passwordController,
                  obscureText: !visibility,
                  onChanged: (text) {
                    store.dispatch(
                        setPassword(password: text.replaceAll(' ', '')));
                  },
                  onEditingComplete: () {
                    store.dispatch(
                        setPassword(password: store.state.userStore.password));
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                          icon: Icon(visibility
                              ? Icons.visibility
                              : Icons.visibility_off),
                          tooltip: 'Show password in plaintext',
                          onPressed: () {
                            this.setState(() {
                              visibility = !visibility;
                            });
                          }),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      labelText: 'Password'),
                ),
              );
            }),
      ],
    ));
  }
}

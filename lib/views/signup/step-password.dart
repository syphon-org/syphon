import 'package:Tether/store/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/store/index.dart';

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
        builder: (context, store) {
          double width = MediaQuery.of(context).size.width;

          return Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  flex: 4,
                  fit: FlexFit.tight,
                  child: Container(
                    width: width * 0.65,
                    constraints: BoxConstraints(
                      maxHeight: Dimensions.mediaSizeMax,
                      maxWidth: Dimensions.mediaSizeMax,
                    ),
                    child: SvgPicture.asset(
                      SIGNUP_PASSWORD_GRAPHIC,
                      semanticsLabel:
                          'User thinking up a password in a swirl of wind',
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
                        padding: EdgeInsets.only(bottom: 8, top: 16),
                        child: Text(
                          'Come up with 4 random words you\'ll\nremember easily',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Create a password',
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
                    width: width * 0.8,
                    height: Dimensions.inputHeight,
                    constraints: BoxConstraints(
                      minWidth: Dimensions.inputWidthMin,
                      maxWidth: Dimensions.inputWidthMax,
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
                              visibility
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                ),
              ],
            ),
          );
        },
      );
}

import 'package:Tether/domain/settings/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';

import 'package:Tether/domain/chat/selectors.dart';

import 'package:Tether/domain/user/model.dart';

// TODO: do you want these?
// const Image(
//   image: NetworkImage(
//       'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
// ),

// Text(
//   'Welcome!',
//   style: Theme.of(context).textTheme.display2,
// ),

class SignupScreen extends StatelessWidget {
  SignupScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double DEFAULT_INPUT_HEIGHT = 52;
    double DEFAULT_BUTTON_HEIGHT = 48;

    return Scaffold(
      body: Center(
          child: StoreConnector<AppState, SettingsStore>(
              converter: (Store<AppState> store) => store.state.settingsStore,
              builder: (context, settingsStore) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: height * 0.05),
                    Text(
                      'SIGNUP',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.display1,
                    ),
                    SizedBox(height: height * 0.05),
                    StoreConnector<AppState, int>(
                        converter: (Store<AppState> store) =>
                            counter(store.state),
                        builder: (context, count) {
                          return Container(
                            width: width * 0.7,
                            height: DEFAULT_INPUT_HEIGHT,
                            margin: const EdgeInsets.all(10.0),
                            constraints: BoxConstraints(
                                minWidth: 200, maxWidth: 400, minHeight: 45),
                            child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                                labelText: 'Alias',
                              ),
                            ),
                          );
                        }),
                    StoreConnector<AppState, int>(
                        converter: (Store<AppState> store) =>
                            counter(store.state),
                        builder: (context, count) {
                          return Container(
                            width: width * 0.7,
                            height: DEFAULT_INPUT_HEIGHT,
                            margin: const EdgeInsets.all(10.0),
                            constraints: BoxConstraints(
                                minWidth: 200, maxWidth: 400, minHeight: 45),
                            child: TextField(
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                                labelText: 'Password',
                              ),
                            ),
                          );
                        }),
                    SizedBox(height: height * 0.05),
                    StoreConnector<AppState, UserStore>(
                      converter: (Store<AppState> store) =>
                          store.state.userStore,
                      builder: (context, userStore) {
                        return Container(
                          width: width * 0.7,
                          height: DEFAULT_BUTTON_HEIGHT,
                          margin: const EdgeInsets.all(10.0),
                          constraints: BoxConstraints(
                              minWidth: 200, maxWidth: 400, minHeight: 45),
                          child: MaterialButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/home');
                            },
                            color: Theme.of(context).primaryColor,
                            minWidth: width * 0.65,
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            child: const Text('Signup',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white)),
                          ),
                        );
                      },
                    ),
                  ],
                );
              })),
    );
  }
}

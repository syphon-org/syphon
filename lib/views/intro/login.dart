import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';

import 'package:Tether/domain/chat/selectors.dart';

import 'package:Tether/domain/user/model.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double DEFAULT_INPUT_HEIGHT = 52;
    double DEFAULT_BUTTON_HEIGHT = 48;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // const Image(
            //   image: NetworkImage(
            //       'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
            // ),
            const Image(
              width: 225,
              height: 225,
              image: AssetImage('assets/icons/noun_polygon_teal.png'),
            ),
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.display2,
            ),
            SizedBox(height: height * 0.025),
            Text(
              'Take back control of chat',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.display1,
            ),
            SizedBox(height: height * 0.05),
            StoreConnector<AppState, int>(
                converter: (Store<AppState> store) => counter(store.state),
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
                        labelText: 'Username',
                      ),
                    ),
                  );
                }),
            StoreConnector<AppState, int>(
                converter: (Store<AppState> store) => counter(store.state),
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
            SizedBox(height: height * 0.025),
            StoreConnector<AppState, UserStore>(
              converter: (Store<AppState> store) => store.state.userStore,
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
                    color: Colors.cyan,
                    minWidth: width * 0.65,
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(30.0)),
                    child: const Text('Login',
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

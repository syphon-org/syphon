import 'package:Tether/domain/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Domain
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/selectors.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';

class HomeserverStep extends StatelessWidget {
  HomeserverStep({Key key}) : super(key: key);
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: height * 0.1),
        Center(
            child: Container(
          height: DEFAULT_INPUT_HEIGHT,
          constraints:
              BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 220),
          child: SvgPicture.asset(SIGNUP_HOMESERVER_GRAPHIC,
              semanticsLabel: 'User hidding behind a message'),
        )),
        SizedBox(height: 24),
        Text(
          'Find a homeserver',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline5,
        ),
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
                  controller: TextEditingController.fromValue(TextEditingValue(
                      text: homeserver(store.state),
                      selection: TextSelection(
                          baseOffset: store.state.userStore.homeserver.length,
                          extentOffset:
                              store.state.userStore.homeserver.length))),
                  onChanged: (text) {
                    store.dispatch(setHomeserver(homeserver: text));
                  },
                  onEditingComplete: () {
                    store.dispatch(setHomeserver(
                        homeserver: store.state.userStore.homeserver));
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        tooltip: 'Find your homeserver',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/search_home',
                          );
                        }),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                    labelText: 'homeserver',
                  ),
                ),
              );
            }),
      ],
    ));
  }
}

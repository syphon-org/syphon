import 'package:Tether/store/user/actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/selectors.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';

class HomeserverStep extends StatelessWidget {
  HomeserverStep({Key key}) : super(key: key);
  final focusNode = FocusNode();

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
                  child: SvgPicture.asset(SIGNUP_HOMESERVER_GRAPHIC,
                      semanticsLabel: 'User hidding behind a message'),
                ),
              ),
              Flexible(
                flex: 1,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Find a homeserver',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headline5,
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
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: homeserver(store.state),
                      selection: TextSelection(
                        baseOffset: store.state.userStore.homeserver.length,
                        extentOffset: store.state.userStore.homeserver.length,
                      ),
                    ),
                  ),
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
                      borderRadius: BorderRadius.circular(34.0),
                    ),
                    labelText: 'homeserver',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

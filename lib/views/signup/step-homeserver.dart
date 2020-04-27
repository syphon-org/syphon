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
          builder: (context, store) {
            double width = MediaQuery.of(context).size.width;

            return Container(
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
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: homeserver(store.state),
                            selection: TextSelection(
                              baseOffset:
                                  store.state.userStore.homeserver.length,
                              extentOffset:
                                  store.state.userStore.homeserver.length,
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
                  ),
                ],
              ),
            );
          });
}

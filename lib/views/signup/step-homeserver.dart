import 'package:syphon/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Store
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/selectors.dart';

// Styling
import 'package:syphon/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syphon/global/dimensions.dart';

class HomeserverStep extends StatelessWidget {
  HomeserverStep({Key key}) : super(key: key);
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        double width = MediaQuery.of(context).size.width;
        double height = MediaQuery.of(context).size.height;

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
                  child: SvgPicture.asset(Assets.heroSignupHomeserver,
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
                        text: props.homeserver,
                        selection: TextSelection(
                          baseOffset: props.homeserver.length,
                          extentOffset: props.homeserver.length,
                        ),
                      ),
                    ),
                    onChanged: (text) {
                      props.onChangeHomeserver(text.trim());
                    },
                    onEditingComplete: () {
                      props.onChangeHomeserver(props.homeserver);
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

class _Props extends Equatable {
  final String homeserver;

  final Function onChangeHomeserver;

  _Props({
    @required this.homeserver,
    @required this.onChangeHomeserver,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        homeserver: store.state.authStore.homeserver,
        onChangeHomeserver: (String text) {
          store.dispatch(setHomeserver(homeserver: text.trim()));
        },
      );

  @override
  List<Object> get props => [
        homeserver,
      ];
}
